import 'dart:async';

import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/error/failure.dart';
import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/core/l10n/failure_messages.dart';
import 'package:driver_diary/core/l10n/l10n.dart';
import 'package:driver_diary/features/admin/domain/admin.dart';
import 'package:driver_diary/features/admin/presentation/admin_providers.dart';
import 'package:driver_diary/features/menu/presentation/screens/menu_screen.dart';
import 'package:driver_diary/features/trips/presentation/providers/trips_providers.dart';
import 'package:driver_diary/features/trips/presentation/widgets/day_skeleton.dart';
import 'package:driver_diary/features/trips/presentation/widgets/day_switcher_bar.dart';
import 'package:driver_diary/features/trips/presentation/widgets/summary_card.dart';
import 'package:driver_diary/features/trips/presentation/widgets/trip_list.dart';
import 'package:driver_diary/features/withdrawals/domain/entities/withdrawal.dart';
import 'package:driver_diary/features/withdrawals/presentation/providers/withdrawals_providers.dart';
import 'package:driver_diary/features/withdrawals/presentation/widgets/withdrawal_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The admin screen's tabs (DESIGN.md §8.6).
enum AdminTab { trips, withdrawals, drivers }

/// «Админка» (DESIGN.md §8.6): the Day layout for any driver or all of them,
/// payout requests to approve or reject, and the drivers with their balances.
class AdminScreen extends ConsumerStatefulWidget {
  const new({this.initialTab = AdminTab.trips, super.key});

  /// The first tab (tests and screenshots).
  final AdminTab initialTab;

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  late AdminTab _tab = widget.initialTab;

  /// Trips of one driver; null = all drivers.
  String? _driver;

  /// «Все» instead of «В обработке».
  bool _allWithdrawals = false;

  /// The withdrawal being approved or rejected (its buttons show progress).
  String? _deciding;
  DkSnackbarHandle? _snack;

  @override
  void dispose() {
    _snack?.close();
    super.dispose();
  }

  WithdrawalStatus? get _status =>
      _allWithdrawals ? null : WithdrawalStatus.pending;

  void _showSnack(String message, {required bool success}) {
    _snack = showDkSnackbar(
      context,
      message: message,
      tone: success ? DkSnackTone.success : DkSnackTone.error,
    );
  }

  String _failureText(Failure failure) {
    final l10n = context.l10n;
    return commonFailureMessage(l10n, failure, offline: l10n.loginOffline);
  }

  Future<void> _refresh() async {
    switch (_tab) {
      case AdminTab.trips:
        final day = ref.read(selectedDayProvider);
        ref.invalidate(dayTripsProvider(day, driverId: _driver));
        await ref.read(dayTripsProvider(day, driverId: _driver).future);
      case AdminTab.withdrawals:
        ref.invalidate(withdrawalsProvider);
        await ref.read(withdrawalsProvider(status: _status).future);
      case AdminTab.drivers:
        ref
          ..invalidate(driversProvider)
          ..invalidate(balanceProvider);
        await ref.read(driversProvider.future);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.dkSpacing;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            try {
              await _refresh();
            } on Object {
              // The tab shows its error state.
            }
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              spacing.screenGutter,
              0,
              spacing.screenGutter,
              spacing.s24 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              DkWordmark(
                title: l10n.appTitle,
                caption: l10n.roleAdmin,
                trailing: DkIconButton(
                  icon: DkIcons.menu,
                  label: l10n.menu,
                  onPressed: () => openMenu(context),
                ),
              ),
              SizedBox(height: spacing.s8),
              DkSegmentedControl<AdminTab>(
                segments: [
                  DkSegment(value: AdminTab.trips, label: l10n.tabTrips),
                  DkSegment(
                    value: AdminTab.withdrawals,
                    label: l10n.tabWithdrawals,
                  ),
                  DkSegment(value: AdminTab.drivers, label: l10n.tabDrivers),
                ],
                selected: _tab,
                onChanged: (tab) {
                  _snack?.close();
                  setState(() => _tab = tab);
                },
              ),
              SizedBox(height: spacing.s8),
              ...switch (_tab) {
                AdminTab.trips => _trips(),
                AdminTab.withdrawals => _withdrawals(),
                AdminTab.drivers => _drivers(),
              },
            ],
          ),
        ),
      ),
    );
  }

  // --- Поездки -------------------------------------------------------------

  List<Widget> _trips() {
    final l10n = context.l10n;
    final spacing = context.dkSpacing;
    final drivers = ref.watch(driversProvider).value ?? const <Account>[];
    final day = ref.watch(selectedDayProvider);
    final trips = ref.watch(dayTripsProvider(day, driverId: _driver));
    final summary = ref.watch(daySummaryProvider(day, driverId: _driver));
    final loaded = (summary.value, trips.value);
    return [
      DkFilterChips<String?>(
        options: [
          (value: null, label: l10n.allDrivers),
          for (final account in drivers)
            (value: account.user.id, label: account.user.displayName),
        ],
        selected: _driver,
        onChanged: (id) => setState(() => _driver = id),
      ),
      SizedBox(height: spacing.s8),
      const DaySwitcherBar(),
      SizedBox(height: spacing.s16),
      switch (loaded) {
        (final s?, final _?) when s.tripsCount == 0 => _state(
          DkEmptyState(title: l10n.emptyTitle),
        ),
        (final s?, final t?) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: spacing.s16,
          children: [
            SummaryCard(summary: s),
            TripList(
              trips: t,
              zone: ref.watch(driverZoneProvider),
              order: ref.watch(tripOrderSettingProvider),
              onSort: () => chooseTripOrder(context, ref),
              driverNames: _driver == null
                  ? ref.watch(driverNamesProvider)
                  : null,
            ),
          ],
        ),
        _ when summary.hasError => _state(
          DkErrorState(
            title: l10n.loadFailedTitle,
            message: l10n.loadFailedMessage,
            retryLabel: l10n.retry,
            isRetrying: summary.isLoading,
            onRetry: () =>
                ref.invalidate(dayTripsProvider(day, driverId: _driver)),
          ),
        ),
        _ => const DaySkeleton(),
      },
    ];
  }

  /// An empty or error state below the controls.
  Widget _state(Widget state) => Padding(
    padding: EdgeInsets.only(top: context.dkSpacing.s48),
    child: state,
  );

  // --- Выводы --------------------------------------------------------------

  List<Widget> _withdrawals() {
    final l10n = context.l10n;
    final spacing = context.dkSpacing;
    final list = ref.watch(withdrawalsProvider(status: _status));
    final names = ref.watch(driverNamesProvider);
    final zone = ref.watch(driverZoneProvider);
    return [
      DkFilterChips<bool>(
        options: [
          (value: false, label: l10n.statusPending),
          (value: true, label: l10n.filterAll),
        ],
        selected: _allWithdrawals,
        onChanged: (all) => setState(() => _allWithdrawals = all),
      ),
      SizedBox(height: spacing.s8),
      switch (list) {
        AsyncValue(value: final items?) when items.isEmpty => _state(
          DkEmptyState(
            title: l10n.adminEmptyTitle,
            message: l10n.adminEmptyMessage,
          ),
        ),
        AsyncValue(value: final items?) => DkTripList(
          children: [
            for (final w in items)
              DkWithdrawalTile(
                prominent: true,
                amount: w.amount,
                subtitle: l10n.driverRow(
                  names[w.driverId] ?? '',
                  l10n.shortDateTime(zone.wallClock(w.createdAt)),
                ),
                status: WithdrawalStatusChip(w.status),
                actions: w.status == WithdrawalStatus.pending
                    ? DkDecisionButtons(
                        rejectLabel: l10n.reject,
                        approveLabel: l10n.approve,
                        approving: _deciding == w.id,
                        onReject: () => _reject(w, names[w.driverId] ?? ''),
                        onApprove: () => _approve(w),
                      )
                    : null,
              ),
          ],
        ),
        AsyncValue(hasError: true) => _state(
          DkErrorState(
            title: l10n.loadFailedTitle,
            message: l10n.loadFailedMessage,
            retryLabel: l10n.retry,
            isRetrying: list.isLoading,
            onRetry: () => ref.invalidate(withdrawalsProvider),
          ),
        ),
        _ => const DkTripList(
          children: [DkSkeleton.tripTile(), DkSkeleton.tripTile()],
        ),
      },
    ];
  }

  Future<void> _approve(Withdrawal withdrawal) async {
    if (_deciding != null) return;
    setState(() => _deciding = withdrawal.id);
    final result = await ref
        .read(withdrawalsRepositoryProvider)
        .approve(withdrawal.id);
    if (!mounted) return;
    await _decided(result, success: context.l10n.markedPaid);
  }

  Future<void> _reject(Withdrawal withdrawal, String driver) async {
    if (_deciding != null) return;
    final l10n = context.l10n;
    final reason = await showGeneralDialog<String>(
      context: context,
      barrierColor: context.dkColors.scrim,
      barrierLabel: l10n.reject,
      pageBuilder: (_, _, _) => _RejectDialog(
        title: l10n.rejectTitle(DkMoney.format(withdrawal.amount)),
        message: l10n.rejectMessage(driver),
      ),
    );
    if (reason == null || !mounted) return;
    setState(() => _deciding = withdrawal.id);
    final result = await ref
        .read(withdrawalsRepositoryProvider)
        .reject(withdrawal.id, reason);
    if (!mounted) return;
    await _decided(result, success: context.l10n.rejected);
  }

  Future<void> _decided(
    Result<Withdrawal> result, {
    required String success,
  }) async {
    if (!mounted) return;
    ref
      ..invalidate(withdrawalsProvider)
      ..invalidate(balanceProvider);
    try {
      await ref.read(withdrawalsProvider(status: _status).future);
    } on Object {
      // The tab shows its error state.
    }
    if (!mounted) return;
    setState(() => _deciding = null);
    switch (result) {
      case Ok():
        _showSnack(success, success: true);
      case Err(:final failure):
        _showSnack(_failureText(failure), success: false);
    }
  }

  // --- Водители ------------------------------------------------------------

  List<Widget> _drivers() {
    final l10n = context.l10n;
    final drivers = ref.watch(driversProvider);
    return [
      switch (drivers) {
        AsyncValue(value: final accounts?) => DkListGroup(
          children: [
            for (final account in accounts) _DriverRow(account, onTap: _act),
          ],
        ),
        AsyncValue(hasError: true) => _state(
          DkErrorState(
            title: l10n.loadFailedTitle,
            message: l10n.loadFailedMessage,
            retryLabel: l10n.retry,
            isRetrying: drivers.isLoading,
            onRetry: () => ref.invalidate(driversProvider),
          ),
        ),
        _ => const DkTripList(
          children: [DkSkeleton.tripTile(), DkSkeleton.tripTile()],
        ),
      },
    ];
  }

  /// Row tap: block / unblock, sign out everywhere.
  Future<void> _act(Account account) {
    final l10n = context.l10n;
    final user = account.user;
    return showDkActionSheet(
      context,
      title: user.displayName,
      subtitle: '@${user.login}',
      actions: [
        (
          icon: account.isActive ? DkIcons.block : DkIcons.unblock,
          label: account.isActive ? l10n.block : l10n.unblock,
          destructive: account.isActive,
          onTap: () =>
              unawaited(_setActive(account, active: !account.isActive)),
        ),
        (
          icon: DkIcons.signOutEverywhere,
          label: l10n.revokeSessions,
          destructive: false,
          onTap: () => unawaited(_confirmRevoke(account)),
        ),
      ],
    );
  }

  Future<void> _setActive(Account account, {required bool active}) async {
    final result = await ref
        .read(adminRepositoryProvider)
        .setActive(account.user.id, active: active);
    if (!mounted) return;
    final l10n = context.l10n;
    switch (result) {
      case Ok():
        ref.invalidate(driversProvider);
        _showSnack(
          active ? l10n.unblockedDone : l10n.blockedDone,
          success: true,
        );
      case Err(:final failure):
        _showSnack(_failureText(failure), success: false);
    }
  }

  Future<void> _confirmRevoke(Account account) {
    final l10n = context.l10n;
    return showDkDialog(
      context,
      icon: DkIcons.signOutEverywhere,
      title: l10n.revokeSessionsTitle,
      message: l10n.revokeSessionsMessage,
      primaryLabel: l10n.revokeConfirm,
      onPrimary: () => unawaited(_revoke(account)),
      secondaryLabel: l10n.cancel,
      onSecondary: () {},
    );
  }

  Future<void> _revoke(Account account) async {
    final result = await ref
        .read(adminRepositoryProvider)
        .revokeSessions(account.user.id);
    if (!mounted) return;
    switch (result) {
      case Ok():
        _showSnack(context.l10n.sessionsRevoked, success: true);
      case Err(:final failure):
        _showSnack(_failureText(failure), success: false);
    }
  }
}

/// A driver with their balance (`moneyM`).
class _DriverRow extends ConsumerWidget {
  const new(this.account, {required this.onTap});

  final Account account;
  final ValueChanged<Account> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = account.user;
    final available = ref
        .watch(balanceProvider(driverId: user.id))
        .value
        ?.available;
    return DkListRow(
      icon: DkIcons.user,
      title: user.displayName,
      subtitle: account.isActive
          ? '@${user.login}'
          : l10n.blockedCaption(user.login),
      trailing: available == null
          ? null
          : DkMoneyText(
              available,
              style: context.dkText.moneyM.copyWith(
                color: context.dkColors.textPrimary,
              ),
            ),
      onTap: () => onTap(account),
    );
  }
}

/// «Отклонить заявку на 1 000 ₸?» with the required «Причина» field; pops
/// with the trimmed reason, or null.
class _RejectDialog extends StatefulWidget {
  const new({required this.title, required this.message});

  final String title;
  final String message;

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reason = _reason.text.trim();
    return DkDialogView(
      icon: DkIcons.rejected,
      title: widget.title,
      message: widget.message,
      content: DkTextField(
        label: l10n.rejectReason,
        controller: _reason,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onChanged: (_) => setState(() {}),
      ),
      primaryLabel: l10n.reject,
      primaryEnabled: reason.isNotEmpty,
      onPrimary: () => Navigator.of(context).pop(reason),
      secondaryLabel: l10n.cancel,
      onSecondary: () => Navigator.of(context).pop(),
      popOnAction: false,
    );
  }
}
