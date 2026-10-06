import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/error/failure.dart';
import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/core/format/date_format.dart';
import 'package:driver_diary/core/providers.dart';
import 'package:driver_diary/core/time/calendar_day.dart';
import 'package:driver_diary/features/trips/domain/entities/trip.dart';
import 'package:driver_diary/features/trips/domain/entities/trip_rules.dart';
import 'package:driver_diary/features/trips/presentation/error_messages.dart';
import 'package:driver_diary/features/trips/presentation/models/trip_form.dart';
import 'package:driver_diary/features/trips/presentation/providers/trips_providers.dart';
import 'package:driver_diary/features/trips/presentation/widgets/trip_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Form for a new trip. Pops with the saved [Trip].
class AddTripScreen extends ConsumerStatefulWidget {
  const new({required this.initialDay, super.key});

  final CalendarDay initialDay;

  @override
  ConsumerState<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends ConsumerState<AddTripScreen> {
  late CalendarDay _day = widget.initialDay;
  ClockTime? _start;
  ClockTime? _end;
  PaymentMethod _payment = PaymentMethod.card;
  final _dateText = TextEditingController();
  final _startText = TextEditingController();
  final _endText = TextEditingController();
  final _amount = TextEditingController();
  final _commission = TextEditingController();

  /// Field errors; shown once the user has tried to save.
  Map<TripField, String> _errors = const {};
  bool _showErrors = false;

  /// Conflict / network / server problems that don't belong to one field.
  String? _banner;

  @override
  void initState() {
    super.initState();
    _dateText.text = formatDayMonth(_day, withYear: true);
  }

  @override
  void dispose() {
    for (final controller in [
      _dateText,
      _startText,
      _endText,
      _amount,
      _commission,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  TripFormInput get _input => TripFormInput(
    day: _day,
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

  void _onChanged() {
    setState(() {
      _banner = null;
      if (_showErrors) {
        _errors = switch (_validate()) {
          TripFormInvalid(:final errors) => errors,
          TripFormValid() => const {},
        };
      }
    });
  }

  Future<void> _save() async {
    setState(() {
      _showErrors = true;
      _banner = null;
    });
    final Trip draft;
    switch (_validate()) {
      case TripFormInvalid(:final errors):
        setState(() => _errors = errors);
        return;
      case TripFormValid(:final trip):
        setState(() => _errors = const {});
        draft = trip;
    }

    final result = await ref
        .read(addTripControllerProvider.notifier)
        .save(draft);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        Navigator.of(context).pop(value);
      case Err(failure: ValidationFailure(:final code, :final field))
          when _formField(field) != null:
        setState(() => _errors = {_formField(field)!: validationMessage(code)});
      case Err(:final failure):
        setState(() => _banner = failureMessage(failure));
    }
  }

  static TripField? _formField(String? name) =>
      TripField.values.where((f) => f.name == name).firstOrNull;

  Future<void> _pickDate() async {
    final zone = ref.read(driverZoneProvider);
    final today = zone.dayOf(ref.read(clockProvider)());
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_day.year, _day.month, _day.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(today.year, today.month, today.day),
    );
    if (picked == null) return;
    _day = CalendarDay(picked.year, picked.month, picked.day);
    _dateText.text = formatDayMonth(_day, withYear: true);
    _onChanged();
  }

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
      helpText: isStart ? 'Начало поездки' : 'Окончание поездки',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    final time = (hour: picked.hour, minute: picked.minute);
    final text = formatClock(time.hour, time.minute);
    if (isStart) {
      _start = time;
      _startText.text = text;
    } else {
      _end = time;
      _endText.text = text;
    }
    _onChanged();
  }

  String? _error(TripField field) => _showErrors ? _errors[field] : null;

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(addTripControllerProvider).isLoading;
    final spacing = context.dkSpacing;
    final digits = [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(8),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Новая поездка')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(spacing.md),
          children: [
            DkTextField(
              label: 'Дата',
              controller: _dateText,
              readOnly: true,
              onTap: _pickDate,
              prefixIcon: Icons.calendar_today_outlined,
            ),
            SizedBox(height: spacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: spacing.sm,
              children: [
                Expanded(
                  child: DkTextField(
                    label: 'Начало',
                    controller: _startText,
                    hint: 'чч:мм',
                    readOnly: true,
                    onTap: () => _pickTime(isStart: true),
                    prefixIcon: Icons.schedule,
                    errorText: _error(TripField.start),
                  ),
                ),
                Expanded(
                  child: DkTextField(
                    label: 'Окончание',
                    controller: _endText,
                    hint: 'чч:мм',
                    readOnly: true,
                    onTap: () => _pickTime(isStart: false),
                    prefixIcon: Icons.schedule,
                    helperText: _input.endsNextDay ? 'На следующий день' : null,
                    errorText: _error(TripField.end),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.md),
            DkTextField(
              label: 'Сумма',
              controller: _amount,
              hint: '2400',
              suffixText: DkMoney.currency,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: digits,
              onChanged: (_) => _onChanged(),
              errorText: _error(TripField.amount),
            ),
            SizedBox(height: spacing.md),
            DkTextField(
              label: 'Комиссия',
              controller: _commission,
              hint: '360',
              suffixText: DkMoney.currency,
              helperText: 'Сколько удержал сервис',
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: digits,
              onChanged: (_) => _onChanged(),
              errorText: _error(TripField.commission),
            ),
            SizedBox(height: spacing.md),
            DkSegmentedControl<PaymentMethod>(
              label: 'Оплата',
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
                  : (method) {
                      _payment = method;
                      _onChanged();
                    },
            ),
            if (_banner case final message?) ...[
              SizedBox(height: spacing.md),
              _Banner(message: message),
            ],
            SizedBox(height: spacing.lg),
            DkButton(label: 'Сохранить', isLoading: saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const new({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: EdgeInsets.all(context.dkSpacing.md),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(context.dkRadii.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: context.dkSpacing.sm,
          children: [
            Icon(
              Icons.error_outline,
              color: colors.onErrorContainer,
              size: context.dkSizes.iconMd,
            ),
            Expanded(
              child: Text(
                message,
                style: context.dkText.body.copyWith(
                  color: colors.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
