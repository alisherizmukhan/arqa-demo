import 'package:design_kit/src/components/dk_button.dart';
import 'package:design_kit/src/theme/dk_context.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Wheel height of the pickers (the iOS default).
const double _wheelHeight = 216;

/// Picks a time of day with an iOS-style wheel in a bottom sheet, on every
/// platform (DESIGN.md §4 DkPickerSheet). 24-hour. Null when dismissed.
Future<({int hour, int minute})?> showDkTimePicker(
  BuildContext context, {
  required int hour,
  required int minute,
  String title = 'Время',
  String doneLabel = 'Готово',
}) async {
  final picked = await _showWheelSheet(
    context,
    title: title,
    doneLabel: doneLabel,
    initial: DateTime(2000, 1, 1, hour, minute),
    picker: (value, onChanged) => CupertinoDatePicker(
      mode: CupertinoDatePickerMode.time,
      use24hFormat: true,
      initialDateTime: value,
      onDateTimeChanged: onChanged,
    ),
  );
  return picked == null ? null : (hour: picked.hour, minute: picked.minute);
}

/// Picks a date between [firstDate] and [lastDate] with an iOS-style wheel
/// in a bottom sheet (DESIGN.md §4 DkPickerSheet). With [todayLabel], the
/// header has a shortcut that selects [lastDate]. Null when dismissed.
Future<DateTime?> showDkDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String title = 'Выберите дату',
  String doneLabel = 'Готово',
  String? todayLabel,
}) {
  DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  final first = dateOnly(firstDate);
  final last = dateOnly(lastDate);
  var initial = dateOnly(initialDate);
  if (initial.isAfter(last)) initial = last;
  if (initial.isBefore(first)) initial = first;
  return _showWheelSheet(
    context,
    title: title,
    doneLabel: doneLabel,
    initial: initial,
    shortcutLabel: todayLabel,
    shortcutValue: last,
    picker: (value, onChanged) => CupertinoDatePicker(
      // A new key per shortcut jump: the wheel re-reads its initial value.
      key: ValueKey(value),
      mode: CupertinoDatePickerMode.date,
      initialDateTime: value,
      minimumDate: first,
      maximumDate: last,
      onDateTimeChanged: (d) => onChanged(dateOnly(d)),
    ),
  );
}

Future<DateTime?> _showWheelSheet(
  BuildContext context, {
  required String title,
  required String doneLabel,
  required DateTime initial,
  required Widget Function(DateTime value, ValueChanged<DateTime> onChanged)
  picker,
  String? shortcutLabel,
  DateTime? shortcutValue,
}) {
  final colors = context.dkColors;
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: colors.surface,
    barrierColor: colors.scrim,
    useSafeArea: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(context.dkRadii.xl),
      ),
    ),
    builder: (_) => DkPickerSheet(
      title: title,
      doneLabel: doneLabel,
      initial: initial,
      picker: picker,
      shortcutLabel: shortcutLabel,
      shortcutValue: shortcutValue,
    ),
  );
}

/// The sheet's content: handle, title (+ shortcut), wheel, «Готово». Pops
/// the route with the chosen value. Public for the showcase and goldens.
class DkPickerSheet extends StatefulWidget {
  /// Creates the sheet content.
  const new({
    required this.title,
    required this.doneLabel,
    required this.initial,
    required this.picker,
    this.shortcutLabel,
    this.shortcutValue,
    super.key,
  });

  /// Sheet title.
  final String title;

  /// «Готово».
  final String doneLabel;

  /// The value shown first.
  final DateTime initial;

  /// Builds the wheel for the current value.
  final Widget Function(DateTime value, ValueChanged<DateTime> onChanged)
  picker;

  /// Header shortcut label (e.g. «Сегодня»); hidden when null.
  final String? shortcutLabel;

  /// The value the shortcut selects.
  final DateTime? shortcutValue;

  @override
  State<DkPickerSheet> createState() => _DkPickerSheetState();
}

class _DkPickerSheetState extends State<DkPickerSheet> {
  late DateTime _value = widget.initial;

  /// The value the wheel was last built with (a shortcut rebuilds it).
  late DateTime _wheelValue = widget.initial;

  @override
  Widget build(BuildContext context) {
    final colors = context.dkColors;
    final text = context.dkText;
    final spacing = context.dkSpacing;
    final sizes = context.dkSizes;
    final shortcut = widget.shortcutLabel;
    final shortcutValue = widget.shortcutValue;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          spacing.s16,
          spacing.s8,
          spacing.s16,
          spacing.s8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: spacing.s40,
                height: spacing.s4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(context.dkRadii.pill),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: sizes.tapTargetMin),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        widget.title,
                        style: text.titleM.copyWith(color: colors.textPrimary),
                      ),
                    ),
                  ),
                  if (shortcut != null && shortcutValue != null)
                    DkButton(
                      label: shortcut,
                      variant: DkButtonVariant.text,
                      onPressed: () =>
                          setState(() => _value = _wheelValue = shortcutValue),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: _wheelHeight,
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: Theme.of(context).brightness,
                  primaryColor: colors.accent,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: text.titleM.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                child: widget.picker(_wheelValue, (v) => _value = v),
              ),
            ),
            SizedBox(height: spacing.s8),
            DkButton(
              label: widget.doneLabel,
              expand: true,
              onPressed: () => Navigator.of(context).pop(_value),
            ),
          ],
        ),
      ),
    );
  }
}
