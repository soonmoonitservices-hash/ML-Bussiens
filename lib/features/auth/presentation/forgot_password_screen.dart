import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/supabase/providers.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/buttons/primary_button.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  int _step = 0;
  bool _loading = false;
  AppError? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final strings = AppLocalizations.of(context);
    if (_step == 2 && _password.text.length < 8) {
      setState(() => _error = DatabaseError(strings.passwordTooShort));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final repository = ref.read(authRepositoryProvider);
    final Result<void> result;
    if (_step == 0) {
      result = await repository.sendRecoveryCode(_email.text);
    } else if (_step == 1) {
      result = await repository.verifyRecoveryCode(
        email: _email.text,
        code: _code.text,
      );
    } else {
      result = await repository.updatePassword(_password.text);
    }
    if (!mounted) return;
    switch (result) {
      case Success():
        if (_step == 2) {
          context.go('/login');
          return;
        }
        setState(() {
          _step += 1;
          _loading = false;
        });
      case Failure(:final error):
        setState(() {
          _error = error;
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final hints = [
      strings.forgotEmailHint,
      strings.forgotCodeHint,
      strings.forgotPasswordHint,
    ];
    final buttons = [
      strings.sendCode,
      strings.verifyCode,
      strings.savePassword,
    ];
    final field = switch (_step) {
      0 => TextField(
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        decoration: InputDecoration(labelText: strings.email),
      ),
      1 => TextField(
        controller: _code,
        keyboardType: TextInputType.number,
        maxLength: 6,
        decoration: InputDecoration(labelText: strings.verificationCode),
      ),
      _ => TextField(
        controller: _password,
        obscureText: true,
        autofillHints: const [AutofillHints.newPassword],
        decoration: InputDecoration(labelText: strings.newPassword),
      ),
    };
    return AppScreen(
      title: strings.forgotPassword,
      onBackPressed: () => context.go('/login'),
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.xs,
          ),
          child: Text(
            hints[_step],
            style: AppText.body.copyWith(color: AppColors.inkMuted),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        field,
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          NoticeBanner(
            message: _error!.localized(strings),
            kind: NoticeKind.error,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: buttons[_step],
          loading: _loading,
          onPressed: _next,
        ),
      ],
    );
  }
}
