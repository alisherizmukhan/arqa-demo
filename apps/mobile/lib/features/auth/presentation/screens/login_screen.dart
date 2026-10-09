import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/error/failure.dart';
import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/core/l10n/failure_messages.dart';
import 'package:driver_diary/core/l10n/l10n.dart';
import 'package:driver_diary/features/auth/presentation/providers/session_providers.dart';
import 'package:driver_diary/features/auth/presentation/widgets/language_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Max width of the login block (DESIGN.md §8.1).
const double _blockMaxWidth = 360;

/// Width of the language switch on the login screen (§8.1).
const double _switchWidth = 200;

/// Sign in (DESIGN.md §8.1). [sessionEnded]: the server ended the previous
/// session, said by a snackbar (§8.5).
class LoginScreen extends ConsumerStatefulWidget {
  const new({this.sessionEnded = false, super.key});

  final bool sessionEnded;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _login = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _signingIn = false;

  /// Under the password field: wrong credentials, too many attempts, or a
  /// blocked account. Cleared when either field changes.
  String? _error;
  DkSnackbarHandle? _snack;

  @override
  void initState() {
    super.initState();
    if (widget.sessionEnded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showSnack(context.l10n.sessionEnded);
      });
    }
  }

  @override
  void dispose() {
    _snack?.close();
    _login.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool get _filled =>
      _login.text.trim().isNotEmpty && _password.text.isNotEmpty;

  void _showSnack(String message) {
    _snack = showDkSnackbar(context, message: message, tone: DkSnackTone.error);
  }

  void _edited(String _) {
    setState(() => _error = null);
  }

  Future<void> _submit() async {
    if (!_filled || _signingIn) return;
    FocusScope.of(context).unfocus();
    _snack?.close();
    setState(() {
      _signingIn = true;
      _error = null;
    });
    final result = await ref
        .read(sessionProvider.notifier)
        .signIn(_login.text.trim(), _password.text);
    if (!mounted) return;
    final l10n = context.l10n;
    switch (result) {
      case Ok():
        TextInput.finishAutofillContext();
      // AppRoot replaces this screen.
      case Err(failure: UnauthorizedFailure()):
        setState(() => _error = l10n.errInvalidCredentials);
      case Err(failure: RateLimitedFailure()):
        setState(() => _error = l10n.errRateLimited);
      case Err(failure: ForbiddenFailure(code: 'account_disabled')):
        setState(() => _error = l10n.errAccountBlocked);
      case Err(:final failure):
        _showSnack(
          commonFailureMessage(l10n, failure, offline: l10n.loginOffline),
        );
    }
    if (mounted) setState(() => _signingIn = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.dkSpacing;
    final colors = context.dkColors;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(spacing.s16),
          children: [
            const Align(
              alignment: AlignmentDirectional.centerEnd,
              child: SizedBox(width: _switchWidth, child: LanguageSwitch()),
            ),
            SizedBox(height: spacing.s64),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _blockMaxWidth),
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DkWordmark(title: l10n.appTitle),
                      SizedBox(height: spacing.s32),
                      Semantics(
                        header: true,
                        child: Text(
                          l10n.loginTitle,
                          style: context.dkText.titleL.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(height: spacing.s24),
                      DkTextField(
                        label: l10n.login,
                        controller: _login,
                        enabled: !_signingIn,
                        autofillHints: const [AutofillHints.username],
                        textInputAction: TextInputAction.next,
                        onChanged: _edited,
                        onSubmitted: (_) => _passwordFocus.requestFocus(),
                      ),
                      SizedBox(height: spacing.s16),
                      DkPasswordField(
                        label: l10n.password,
                        controller: _password,
                        focusNode: _passwordFocus,
                        showLabel: l10n.showPassword,
                        hideLabel: l10n.hidePassword,
                        enabled: !_signingIn,
                        errorText: _error,
                        textInputAction: TextInputAction.done,
                        onChanged: _edited,
                        onSubmitted: (_) => _submit(),
                      ),
                      SizedBox(height: spacing.s24),
                      DkButton(
                        label: _signingIn ? l10n.signingIn : l10n.signIn,
                        expand: true,
                        isLoading: _signingIn,
                        onPressed: _filled ? _submit : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
