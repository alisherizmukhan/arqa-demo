import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/l10n/l10n.dart';
import 'package:driver_diary/features/withdrawals/domain/entities/withdrawal.dart';
import 'package:flutter/widgets.dart';

/// «В обработке» / «Выплачено» / «Отклонено» (icon + text, §8.0).
class WithdrawalStatusChip extends StatelessWidget {
  const new(this.status, {super.key});

  final WithdrawalStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return switch (status) {
      WithdrawalStatus.pending => DkStatusChip(
        kind: DkStatusKind.pending,
        label: l10n.statusPending,
      ),
      WithdrawalStatus.paid => DkStatusChip(
        kind: DkStatusKind.paid,
        label: l10n.statusPaid,
      ),
      WithdrawalStatus.rejected => DkStatusChip(
        kind: DkStatusKind.rejected,
        label: l10n.statusRejected,
      ),
    };
  }
}
