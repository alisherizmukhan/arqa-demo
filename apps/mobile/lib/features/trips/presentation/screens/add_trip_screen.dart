import 'dart:async';
import 'dart:math' as math;

import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/error/failure.dart';
import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/core/l10n/strings_ru.dart';
import 'package:driver_diary/core/providers.dart';
import 'package:driver_diary/core/time/calendar_day.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/domain/entities/trip_rules.dart';
import 'package:driver_diary/features/trips/presentation/error_messages.dart';
import 'package:driver_diary/features/trips/presentation/models/trip_form.dart';
import 'package:driver_diary/features/trips/presentation/providers/trips_providers.dart';
import 'package:driver_diary/features/trips/presentation/widgets/trip_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Waits between automatic resends after a network/server failure
/// (DESIGN.md §5.9): 2 s, 4 s, 8 s, then every 30 s while the form is open.
const addTripRetryDelays = [
  Duration(seconds: 2),
  Duration(seconds: 4),
  Duration(seconds: 8),
  Duration(seconds: 30),
];

/// Full-screen form for a new trip on [day] (DESIGN.md §5.6–5.11). Pops with
/// the saved [Trip].
class AddTripScreen extends ConsumerStatefulWidget {
  const new({required this.day, this.initialInput, super.key});

  /// The day selected on the Day screen; the trip starts on it.
  final CalendarDay day;

  /// Prefilled values (tests and screenshots).
  final TripFormInput? initialInput;

  @override
  ConsumerState<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends ConsumerState<AddTripScreen> {
  late ClockTime? _start = widget.initialInput?.start;
  late ClockTime? _end = widget.initialInput?.end;
  late PaymentMethod _payment =
      widget.initialInput?.payment ?? PaymentMethod.card;
  late final DkMoneyEditingController _amount = _moneyController(
    widget.initialInput?.amountText,
  );
  late final DkMoneyEditingController _commission = _moneyController(
    widget.initialInput?.commissionText,
  );
  final _amountFocus = FocusNode();
  final _commissionFocus = FocusNode();
  final GlobalKey _bottomBarKey = GlobalKey();

  /// Fields whose errors are shown: left (blur) or picked, §5.7.
  final _touched = <TripField>{};

  /// Save was pressed: every error is shown.
  bool _submitted = false;

  /// Server 422s for a field, until that field changes.
  final _serverErrors = <TripField, String>{};

  DkSnackbarHandle? _snack;

  /// A sent trip whose outcome is unknown (network/server failure). It is
  /// resent with the same id on the [addTripRetryDelays] schedule until it
  /// succeeds, the user edits the form, or the form closes.
  Trip? _unsent;
  int _retryCount = 0;
  Timer? _retryTimer;

  /// A request is in flight (no second one is started).
  bool _sending = false;

  static DkMoneyEditingController _moneyController(String? text) {
    return DkMoneyEditingController(amount: DkMoney.parse(text ?? ''));
  }

  @override
  void initState() {
    super.initState();
    _amountFocus.addListener(() => _onBlur(_amountFocus, TripField.amount));
    _commissionFocus.addListener(
      () => _onBlur(_commissionFocus, TripField.commission),
    );
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _snack?.close();
    _amount.dispose();
    _commission.dispose();
    _amountFocus.dispose();
    _commissionFocus.dispose();
    super.dispose();
  }

  void _onBlur(FocusNode node, TripField field) {
    if (!node.hasFocus && mounted) setState(() => _touched.add(field));
  }

  TripFormInput get _input => TripFormInput(
    day: widget.day,
    start: _start,
    end: _end,
    amountText: _amount.text,
    commissionText: _commission.text,
    payment: _payment,
  );

  TripFormResult _validate() => validateTripForm(
    _input,
    zone: ref.read(driverZoneProvider),
    id: const Uuid().v4(),
  );

  Map<TripField, String> get _errors => {
    if (_validate() case TripFormInvalid(:final errors)) ...errors,
    ..._serverErrors,
  };

  /// Errors the user should see now.
  Map<TripField, String> get _visibleErrors => {
    for (final MapEntry(:key, :value) in _errors.entries)
      if (_submitted || _touched.contains(key)) key: value,
  };

  void _edited(TripField field) {
    _stopRetrying();
    setState(() => _serverErrors.remove(field));
  }

  /// The user changed the trip after a failed send: the old payload is not
  /// resent (the next Save gets a new id, §5.9), and its snackbar goes.
  void _stopRetrying() {
    if (_unsent == null) return;
    _retryTimer?.cancel();
    _unsent = null;
    _retryCount = 0;
    _snack?.close();
  }

  /// Anything typed or picked: closing then asks for confirmation (§5.6).
  bool get _hasInput {
    final initial = widget.initialInput;
    return _start != null ||
        _end != null ||
        _amount.text.isNotEmpty ||
        _commission.text.isNotEmpty ||
        _payment != (initial?.payment ?? PaymentMethod.card);
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    final Trip draft;
    switch (_validate()) {
      case TripFormInvalid():
        return;
      case TripFormValid(:final trip):
        draft = trip;
    }
    if (_serverErrors.isNotEmpty) return;
    FocusScope.of(context).unfocus();
    _retryTimer?.cancel();
    _retryCount = 0;
    await _send(draft);
  }

  /// «Повторить»: resend now and restart the 2/4/8/30 s schedule.
  void _retryNow() {
    final trip = _unsent;
    if (trip == null) return;
    _retryTimer?.cancel();
    _retryCount = 0;
    unawaited(_send(trip));
  }

  void _scheduleRetry() {
    final delay =
        addTripRetryDelays[math.min(
          _retryCount,
          addTripRetryDelays.length - 1,
        )];
    _retryCount++;
    _retryTimer = Timer(delay, () {
      if (_unsent case final trip?) unawaited(_send(trip, quietly: true));
    });
  }

  /// Sends [trip]. Automatic resends are [quietly]: the form stays editable
  /// and the button keeps its label (mockup 10).
  Future<void> _send(Trip trip, {bool quietly = false}) async {
    if (_sending) return;
    _sending = true;
    final result = await ref
        .read(addTripControllerProvider.notifier)
        .save(trip, quietly: quietly);
    _sending = false;
    if (!mounted) return;
    if (result case Err(:final failure) when isTransient(failure)) {
      // Unknown outcome: keep resending the same trip (same id). The
      // snackbar opens after the first failure and stays until success.
      final first = _unsent == null;
      _unsent = trip;
      if (first || !(_snack?.isOpen ?? false)) {
        _showError(failureMessage(failure), retry: true);
      }
      _scheduleRetry();
      return;
    }
    _retryTimer?.cancel();
    _unsent = null;
    _retryCount = 0;
    switch (result) {
      case Ok(:final value):
        _snack?.close();
        Navigator.of(context).pop(value);
      case Err(failure: ValidationFailure(:final code, :final field))
          when _formField(field) != null:
        _snack?.close();
        setState(
          () => _serverErrors[_formField(field)!] = validationMessage(code),
        );
      case Err(failure: ConflictFailure()):
        _snack?.close();
        await _showConflict();
      case Err(:final failure):
        _showError(failureMessage(failure), retry: false);
    }
  }

  static TripField? _formField(String? name) =>
      TripField.values.where((f) => f.name == name).firstOrNull;

  /// Error snackbar 12 above the bottom bar (§4 DkSnackbar).
  void _showError(String message, {required bool retry}) {
    final bar = _bottomBarKey.currentContext?.size?.height ?? 0;
    _snack = showDkSnackbar(
      context,
      message: message,
      tone: DkSnackTone.error,
      actionLabel: retry ? S.retry : null,
      onAction: retry ? _retryNow : null,
      bottom:
          MediaQuery.viewInsetsOf(context).bottom + bar + context.dkSpacing.s12,
    );
  }

  /// §5.11 (approved: no stored values; see DECISIONS.md).
  Future<void> _showConflict() => showDkDialog(
    context,
    icon: DkIcons.alert,
    title: S.conflictTitle,
    message: S.conflictMessage,
    primaryLabel: S.conflictKeep,
    onPrimary: () {
      ref.invalidate(dayTripsProvider);
      Navigator.of(context).pop();
    },
    secondaryLabel: S.conflictNew,
    // A new id is used: the conflicting attempt is not retried.
    onSecondary: _save,
  );

  Future<void> _pickTime({required bool isStart}) async {
    final zone = ref.read(driverZoneProvider);
    final now = zone.wallClock(ref.read(clockProvider)());
    final current = isStart ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: current?.hour ?? now.hour,
        minute: current?.minute ?? now.minute,
      ),
      helpText: isStart ? S.startPickerHelp : S.endPickerHelp,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (!mounted) return;
    final field = isStart ? TripField.start : TripField.end;
    setState(() {
      _touched.add(field);
      if (picked == null) return;
      final time = (hour: picked.hour, minute: picked.minute);
      if (isStart) {
        _start = time;
      } else {
        _end = time;
      }
      _serverErrors
        ..remove(TripField.start)
        ..remove(TripField.end);
      _stopRetrying();
    });
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(addTripControllerProvider).isLoading;
    final spacing = context.dkSpacing;
    final input = _input;
    final errors = _errors;
    final visible = _visibleErrors;
    String? clock(ClockTime? t) =>
        t == null ? null : DkFormat.clock(t.hour, t.minute);

    return PopScope(
      // Close (✕ or system back) with unsaved input asks first (§5.6).
      canPop: !_hasInput,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_confirmDiscard());
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              DkModalAppBar(
                title: S.formTitle,
                subtitle: DkFormat.date(_date(widget.day)),
                onClose: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.screenGutter,
                    vertical: spacing.s8,
                  ),
                  children: [
                    _TimeRow(
                      start: DkTimeField(
                        label: S.start,
                        value: clock(_start),
                        enabled: !saving,
                        invalid: visible.containsKey(TripField.start),
                        onTap: () => _pickTime(isStart: true),
                      ),
                      end: DkTimeField(
                        label: S.end,
                        value: clock(_end),
                        enabled: !saving,
                        invalid: visible.containsKey(TripField.end),
                        // The badge only for a valid next-day end (mockup 08
                        // shows none next to the error).
                        trailing:
                            input.endsNextDay &&
                                !errors.containsKey(TripField.end)
                            ? const DkBadge(S.nextDayBadge)
                            : null,
                        onTap: () => _pickTime(isStart: false),
                      ),
                      message: _timeMessage(input, errors, visible),
                    ),
                    SizedBox(height: spacing.s20),
                    DkTextField.money(
                      label: S.amount,
                      controller: _amount,
                      focusNode: _amountFocus,
                      enabled: !saving,
                      helper: S.amountHelper,
                      errorText: visible[TripField.amount],
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _edited(TripField.amount),
                    ),
                    SizedBox(height: spacing.s20),
                    DkTextField.money(
                      label: S.commission,
                      controller: _commission,
                      focusNode: _commissionFocus,
                      enabled: !saving,
                      helper: switch (input.net) {
                        final net? => S.netHelper(net),
                        null => null,
                      },
                      errorText: visible[TripField.commission],
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => _edited(TripField.commission),
                    ),
                    SizedBox(height: spacing.s20),
                    DkSegmentedControl<PaymentMethod>(
                      label: S.payment,
                      segments: [
                        for (final method in PaymentMethod.values)
                          DkSegment(
                            value: method,
                            label: method.toKit().label,
                            icon: method.toKit().icon,
                          ),
                      ],
                      selected: _payment,
                      onChanged: saving
                          ? null
                          : (method) => setState(() {
                              _payment = method;
                              _serverErrors.remove(TripField.payment);
                              _stopRetrying();
                            }),
                    ),
                  ],
                ),
              ),
              // In the body, not `bottomNavigationBar`: the body shrinks above
              // the keyboard, so Save stays pinned right above it (§5.6).
              DkBottomBar(
                key: _bottomBarKey,
                child: DkButton(
                  label: saving ? S.saving : S.save,
                  expand: true,
                  isLoading: saving,
                  // §5.7: disabled while any error is shown.
                  onPressed: visible.isEmpty ? _save : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// §5.6: «If the user closes with unsaved input → confirm discard».
  Future<void> _confirmDiscard() => showDkDialog(
    context,
    icon: DkIcons.alert,
    title: S.discardTitle,
    message: S.discardMessage,
    primaryLabel: S.discardKeep,
    onPrimary: () {},
    secondaryLabel: S.discardLeave,
    // pop() ignores PopScope (only maybePop and system back consult it).
    onSecondary: () => Navigator.of(context).pop(),
  );

  /// The one line under the time row: an error, the midnight explanation
  /// (§5.10) or the duration.
  static DkFieldMessage? _timeMessage(
    TripFormInput input,
    Map<TripField, String> errors,
    Map<TripField, String> visible,
  ) {
    if (visible[TripField.end] ?? visible[TripField.start] case final error?) {
      return DkFieldMessage(text: error, isError: true);
    }
    final duration = input.duration;
    if (duration == null ||
        errors.containsKey(TripField.start) ||
        errors.containsKey(TripField.end)) {
      return null;
    }
    return DkFieldMessage(
      text: input.endsNextDay
          ? S.midnightHelper(
              endDay: _date(input.endDay),
              startDay: _date(input.day),
              duration: duration,
            )
          : S.durationHelper(duration),
    );
  }

  static DateTime _date(CalendarDay day) =>
      DateTime(day.year, day.month, day.day);
}

/// Two time fields side by side (gap 12) and one message under them (gap 6).
class _TimeRow extends StatelessWidget {
  const new({required this.start, required this.end, this.message});

  final Widget start;
  final Widget end;
  final Widget? message;

  @override
  Widget build(BuildContext context) {
    final spacing = context.dkSpacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: spacing.s6,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: spacing.s12,
          children: [
            Expanded(child: start),
            Expanded(child: end),
          ],
        ),
        ?message,
      ],
    );
  }
}
