import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/l10n/l10n.dart';
import 'package:driver_diary/features/admin/presentation/screens/admin_screen.dart';
import 'package:driver_diary/features/auth/presentation/providers/session_providers.dart';
import 'package:driver_diary/features/auth/presentation/screens/login_screen.dart';
import 'package:driver_diary/features/trips/presentation/screens/day_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The first route: login when signed out, else the role's home (driver →
/// Day screen, admin → Admin screen). Pages pushed during a session (menu,
/// withdrawals) close when the session changes.
class AppRoot extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(currentUserProvider, (previous, next) {
      if (previous != next) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
    final session = ref.watch(sessionProvider);
    return switch (session) {
      AsyncData(value: SignedIn(:final user)) =>
        user.isAdmin ? const AdminScreen() : const DayScreen(),
      AsyncData(value: SignedOut(:final ended)) => LoginScreen(
        sessionEnded: ended,
      ),
      AsyncError() => _StartupError(
        retrying: session.isLoading,
        onRetry: () => ref.invalidate(sessionProvider),
      ),
      _ => const _Splash(),
    };
  }
}

/// While the saved session is checked (a moment).
class _Splash extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Semantics(
      label: context.l10n.loading,
      child: const SizedBox.expand(),
    ),
  );
}

/// The saved session could not be checked (offline at start).
class _StartupError extends StatelessWidget {
  const new({required this.retrying, required this.onRetry});

  final bool retrying;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(context.dkSpacing.screenGutter),
          child: DkErrorState(
            title: l10n.loadFailedTitle,
            message: l10n.loadFailedMessage,
            retryLabel: l10n.retry,
            isRetrying: retrying,
            onRetry: onRetry,
          ),
        ),
      ),
    );
  }
}
