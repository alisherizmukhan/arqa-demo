import 'dart:async';

import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/error/failure.dart';
import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/core/l10n/failure_messages.dart';
import 'package:driver_diary/core/l10n/l10n.dart';
import 'package:driver_diary/core/network/resend_schedule.dart';
import 'package:driver_diary/features/trips/presentation/providers/trips_providers.dart';
import 'package:driver_diary/features/withdrawals/domain/entities/withdrawal.dart';
import 'package:driver_diary/features/withdrawals/presentation/providers/withdrawals_providers.dart';
import 'package:driver_diary/features/withdrawals/presentation/widgets/withdrawal_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// «Вывод средств» (DESIGN.md §8.4): the balance, the amount, the history.
///
/// A request gets its id (UUID v4) when «Вывести» is tapped. After a network
/// or server failure it is resent with the **same** id (2/4/8/30 s, and
/// «Повторить»), so the money never leaves twice; editing the amount drops
/// it, and the next tap gets a new id.
class WithdrawScreen extends ConsumerStatefulWidget {
  const new({this.initialAmount, super.key});

  /// Prefilled amount (tests and screenshots).
  final int? initialAmount;

  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

/// The snackbar above the bottom bar.
typedef _Snack = ({String message, DkSnackTone tone, bool retry});

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  late final _amount = DkMoneyEditingController(amount: widget.initialAmount);
  final _scroll = ScrollController();

  /// A sent request whose outcome is unknown: resent until it succeeds, the
  /// amount is edited, or the screen closes.
  ({String id, int amount})? _unsent;
  int _retryCount = 0;
  Timer? _retryTimer;
  bool _sending = false;

  /// The server refused the amount (422), until it is edited.
  String? _serverError;

  _Snack? _snack;
  Timer? _snackTimer;

  @override
  void dispose() {
    _retryTimer?.cancel();
    _snackTimer?.cancel();
    _amount.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _edited() {
    if (_unsent != null) {
      _retryTimer?.cancel();
      _unsent = null;
      _retryCount = 0;
      _hideSnack();
    }
    setState(() => _serverError = null);
  }

  /// The error under the field, if any (empty field: none, just disabled).
  String? _amountError(Balance balance) {
    if (_serverError case final error?) return error;
    final amount = _amount.amount;
    if (amount == null) return null;
    final l10n = context.l10n;
    return switch (validateWithdrawAmount(amount, balance)) {
      WithdrawAmountError.notPositive => l10n.errAmount,
      WithdrawAmountError.insufficient => l10n.errInsufficient,
      null => null,
    };
  }

  void _showSnack(_Snack snack) {
    _snackTimer?.cancel();
    setState(() => _snack = snack);
    if (snack.tone == DkSnackTone.success) {
      _snackTimer = Timer(DkMotion.successSnack, _hideSnack);
    }
  }

  void _hideSnack() {
    _snackTimer?.cancel();
    if (_snack == null) return;
    if (mounted) {
      setState(() => _snack = null);
    } else {
      _snack = null;
    }
  }

  Future<void> _withdraw() async {
    final amount = _amount.amount;
    if (amount == null) return;
    FocusScope.of(context).unfocus();
    _retryTimer?.cancel();
    _retryCount = 0;
    // The same amount after a failure is the same request (same id).
    final request = switch (_unsent) {
      (:final id, amount: final unsent) when unsent == amount => (
        id: id,
        amount: amount,
      ),
      _ => (id: const Uuid().v4(), amount: amount),
    };
    await _send(request);
  }

  void _retryNow() {
    final request = _unsent;
    if (request == null) return;
    _retryTimer?.cancel();
    _retryCount = 0;
    unawaited(_send(request));
  }

  Future<void> _send(
    ({String id, int amount}) request, {
    bool quietly = false,
  }) async {
    if (_sending) return;
    _sending = true;
    final result = await ref
        .read(withdrawControllerProvider.notifier)
        .send(id: request.id, amount: request.amount, quietly: quietly);
    _sending = false;
    if (!mounted) return;
    final l10n = context.l10n;
    if (result case Err(:final failure) when isTransient(failure)) {
      final first = _unsent == null;
      _unsent = request;
      if (first || _snack == null) {
        _showSnack((
          message: l10n.withdrawOffline,
          tone: DkSnackTone.error,
          retry: true,
        ));
      }
      _retryTimer = Timer(resendDelay(_retryCount++), () {
        if (_unsent case final pending?) {
          unawaited(_send(pending, quietly: true));
        }
      });
      return;
    }
    _retryTimer?.cancel();
    _unsent = null;
    _retryCount = 0;
    switch (result) {
      case Ok(:final value):
        await _created(value);
      case Err(failure: ValidationFailure(:final code)):
        _hideSnack();
        setState(
          () => _serverError = code == 'insufficient_funds'
              ? l10n.errInsufficient
              : l10n.errAmount,
        );
      case Err(failure: ConflictFailure(code: 'withdrawal_conflict')):
        _hideSnack();
        await showDkDialog(
          context,
          icon: DkIcons.alert,
          title: l10n.withdrawConflict,
          message: l10n.withdrawConflictMessage,
          primaryLabel: l10n.ok,
          onPrimary: () => ref.invalidate(withdrawalsProvider),
        );
      case Err(:final failure):
        _showSnack((
          message: commonFailureMessage(
            l10n,
            failure,
            offline: l10n.withdrawOffline,
          ),
          tone: DkSnackTone.error,
          retry: false,
        ));
    }
  }

  /// §8.4 success: back to the top, the new row highlighted, a snackbar.
  Future<void> _created(Withdrawal withdrawal) async {
    _amount.clear();
    setState(() => _serverError = null);
    try {
      await ref.read(withdrawalsProvider().future);
    } on Object {
      // The error state shows instead.
    }
    if (!mounted) return;
    ref.read(highlightedWithdrawalProvider.notifier).flash(withdrawal.id);
    _showSnack((
      message: context.l10n.withdrawCreated,
      tone: DkSnackTone.success,
      retry: false,
    ));
    if (_scroll.hasClients) {
      await _scroll.animateTo(
        0,
        duration: MediaQuery.disableAnimationsOf(context)
            ? const Duration(milliseconds: 1)
            : DkMotion.reveal,
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.dkSpacing;
    final balance = ref.watch(balanceProvider());
    final history = ref.watch(withdrawalsProvider());
    final sendingVisibly = ref.watch(withdrawControllerProvider).isLoading;
    final loadedBalance = balance.value;
    final loadedHistory = history.value;
    final loaded = loadedBalance != null && loadedHistory != null;
    final failed = !loaded && (balance.hasError || history.hasError);

    final error = loadedBalance == null ? null : _amountError(loadedBalance);
    final canSend =
        loadedBalance != null &&
        loadedBalance.available > 0 &&
        _amount.amount != null &&
        error == null &&
        !sendingVisibly;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DkModalAppBar(
              title: l10n.withdraw,
              leadingIcon: DkIcons.previous,
              closeLabel: l10n.back,
              onClose: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: failed
                        ? Padding(
                            padding: EdgeInsets.all(spacing.screenGutter),
                            child: DkErrorState(
                              title: l10n.loadFailedTitle,
                              message: l10n.loadFailedMessage,
                              retryLabel: l10n.retry,
                              isRetrying:
                                  balance.isLoading || history.isLoading,
                              onRetry: () => ref
                                ..invalidate(balanceProvider)
                                ..invalidate(withdrawalsProvider),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              ref
                                ..invalidate(balanceProvider)
                                ..invalidate(withdrawalsProvider);
                              await ref.read(withdrawalsProvider().future);
                            },
                            child: ListView(
                              controller: _scroll,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.all(spacing.s16),
                              children: loaded
                                  ? _content(
                                      loadedBalance,
                                      loadedHistory,
                                      error: error,
                                      sending: sendingVisibly,
                                    )
                                  : const [_WithdrawSkeleton()],
                            ),
                          ),
                  ),
                  if (_snack case final snack?)
                    Positioned(
                      left: spacing.s16,
                      right: snack.tone == DkSnackTone.success
                          ? null
                          : spacing.s16,
                      bottom: spacing.s12,
                      child: Semantics(
                        liveRegion: true,
                        child: DkSnackbarView(
                          key: ValueKey(snack),
                          message: snack.message,
                          tone: snack.tone,
                          actionLabel: snack.retry ? l10n.retry : null,
                          onAction: snack.retry ? _retryNow : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // In the body, as on the add-trip form: the button stays right
            // above the keyboard.
            DkBottomBar(
              child: DkButton(
                label: sendingVisibly ? l10n.sending : l10n.withdrawButton,
                expand: true,
                isLoading: sendingVisibly,
                onPressed: canSend ? _withdraw : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(
    Balance balance,
    List<Withdrawal> history, {
    required String? error,
    required bool sending,
  }) {
    final l10n = context.l10n;
    final spacing = context.dkSpacing;
    final colors = context.dkColors;
    final zone = ref.watch(driverZoneProvider);
    final highlighted = ref.watch(highlightedWithdrawalProvider);
    return [
      DkBalanceCard(
        label: l10n.availableToWithdraw,
        amount: balance.available,
        tiles: [
          (label: l10n.cardTotal, amount: balance.cardTotal, deduction: false),
          (
            label: l10n.summaryCommission,
            amount: balance.commissionTotal,
            deduction: true,
          ),
          (
            label: l10n.withdrawn,
            amount: balance.withdrawnTotal,
            deduction: true,
          ),
        ],
      ),
      SizedBox(height: spacing.s8),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: spacing.s4),
        child: Text(
          l10n.cashNote,
          style: context.dkText.caption.copyWith(color: colors.textTertiary),
        ),
      ),
      SizedBox(height: spacing.s16),
      if (balance.available <= 0)
        DkInfoRow(text: l10n.nothingToWithdraw)
      else
        DkTextField.money(
          label: l10n.withdrawAmount,
          controller: _amount,
          enabled: !sending,
          helper: l10n.maxHint(DkMoney.format(balance.available)),
          errorText: error,
          textInputAction: TextInputAction.done,
          onChanged: (_) => _edited(),
          trailing: DkButton(
            label: l10n.all,
            variant: DkButtonVariant.text,
            onPressed: sending
                ? null
                : () {
                    final text = DkMoney.formatNumber(balance.available);
                    _amount.value = TextEditingValue(
                      text: text,
                      selection: TextSelection.collapsed(offset: text.length),
                    );
                    _edited();
                  },
          ),
        ),
      SizedBox(height: spacing.s24),
      DkListHeader(title: l10n.history),
      SizedBox(height: spacing.s8),
      if (history.isEmpty)
        DkCard(
          child: Text(
            l10n.noWithdrawals,
            style: context.dkText.bodyS.copyWith(color: colors.textSecondary),
          ),
        )
      else
        DkTripList(
          children: [
            for (final w in history)
              DkWithdrawalTile(
                amount: w.amount,
                subtitle: l10n.fullDateTime(zone.wallClock(w.createdAt)),
                note: w.status == WithdrawalStatus.rejected
                    ? w.rejectReason
                    : null,
                status: WithdrawalStatusChip(w.status),
                highlighted: w.id == highlighted,
              ),
          ],
        ),
    ];
  }
}

/// Loading (§8.4): the balance card and three history rows.
class _WithdrawSkeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final spacing = context.dkSpacing;
    return Semantics(
      label: context.l10n.loading,
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DkSkeleton.summaryCard(),
          SizedBox(height: spacing.s24),
          const DkSkeleton.listHeader(),
          SizedBox(height: spacing.s8),
          const DkTripList(
            children: [
              DkSkeleton.tripTile(),
              DkSkeleton.tripTile(),
              DkSkeleton.tripTile(),
            ],
          ),
        ],
      ),
    );
  }
}
