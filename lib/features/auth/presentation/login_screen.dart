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
import 'package:warenbestand/shared/widgets/inputs/language_picker.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  AppError? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ref
        .read(authRepositoryProvider)
        .signIn(_email.text, _password.text);
    if (!mounted) return;
    switch (result) {
      case Success():
        await ref.read(sessionControllerProvider).refresh();
        if (!mounted) return;
        final from = GoRouterState.of(context).uri.queryParameters['from'];
        context.go(from?.startsWith('/') ?? false ? from ?? '/home' : '/home');
      case Failure(:final error):
        setState(() {
          _loading = false;
          _error = error;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AppScreen(
      title: strings.appTitle,
      showBack: false,
      children: [
        if (ref.read(sessionControllerProvider).blockedNotice) ...[
          NoticeBanner(message: strings.accessBlocked, kind: NoticeKind.error),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.lg),
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(labelText: strings.email),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _loading ? null : _submit(),
                decoration: InputDecoration(labelText: strings.password),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                NoticeBanner(
                  message: _error!.localized(strings),
                  kind: NoticeKind.error,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: strings.login,
                loading: _loading,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () => context.go('/forgot-password'),
                  child: Text(strings.forgotPassword),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const LanguagePicker(),
            ],
          ),
        ),
      ],
    );
  }
}
