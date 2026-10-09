import 'dart:async';

import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/config/app_config.dart';
import 'package:driver_diary/core/l10n/l10n.dart';
import 'package:driver_diary/features/auth/presentation/providers/session_providers.dart';
import 'package:driver_diary/features/auth/presentation/widgets/language_switch.dart';
import 'package:driver_diary/features/withdrawals/presentation/providers/withdrawals_providers.dart';
import 'package:driver_diary/features/withdrawals/presentation/screens/withdraw_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the menu (from the Day screen's and the admin's header).
Future<void> openMenu(BuildContext context) =>
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const MenuScreen()));

/// The menu (DESIGN.md §8.3): profile, «Вывод средств» (drivers), language,
/// «Выйти» with a confirmation, the app version.
class MenuScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.dkSpacing;
    final colors = context.dkColors;
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold();
    final driver = !user.isAdmin;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DkModalAppBar(
              title: l10n.menu,
              leadingIcon: DkIcons.previous,
              closeLabel: l10n.back,
              onClose: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  spacing.s16,
                  spacing.s16,
                  spacing.s16,
                  spacing.s16 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  DkProfileCard(
                    name: user.displayName,
                    caption: l10n.profileCaption(
                      user.login,
                      driver ? l10n.roleDriver : l10n.roleAdmin,
                    ),
                  ),
                  SizedBox(height: spacing.s16),
                  DkListGroup(
                    children: [
                      if (driver) const _WithdrawRow(),
                      DkListRow(icon: DkIcons.languages, title: l10n.language),
                      const DkListAttachment(child: LanguageSwitch()),
                    ],
                  ),
                  SizedBox(height: spacing.s16),
                  DkListGroup(
                    children: [
                      DkListRow(
                        icon: DkIcons.logOut,
                        title: l10n.logout,
                        destructive: true,
                        onTap: () => _confirmLogout(context, ref),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.s24),
                  Text(
                    l10n.appVersion(AppConfig.version),
                    textAlign: TextAlign.center,
                    style: context.dkText.caption.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return showDkDialog(
      context,
      icon: DkIcons.logOut,
      title: l10n.logoutTitle,
      message: l10n.logoutMessage,
      primaryLabel: l10n.logout,
      // AppRoot closes the menu and shows the login screen.
      onPrimary: () => unawaited(ref.read(sessionProvider.notifier).signOut()),
      secondaryLabel: l10n.cancel,
      onSecondary: () {},
    );
  }
}

/// «Вывод средств» with «Доступно 1 815 ₸» (from `/balance`).
class _WithdrawRow extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final available = ref.watch(balanceProvider()).value?.available;
    return DkListRow(
      icon: DkIcons.wallet,
      title: l10n.withdraw,
      subtitle: available == null
          ? null
          : l10n.available(DkMoney.format(available)),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const WithdrawScreen())),
    );
  }
}
