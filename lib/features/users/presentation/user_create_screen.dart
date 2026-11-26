import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/supabase/providers.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/buttons/primary_button.dart';
import 'package:warenbestand/shared/widgets/dialogs/app_snack.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';
import 'package:warenbestand/shared/widgets/inputs/choice_chips.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';
import 'package:warenbestand/shared/widgets/layout/sticky_action.dart';
import 'package:warenbestand/shared/widgets/layout/unsaved_changes_guard.dart';

/// Neuen Benutzer anlegen. Standard: in der eigenen Firma; er sieht dieselben
/// Daten und darf alles wie du. Nur der Superadmin kann stattdessen „Neue
/// Firma“ wählen: Der Benutzer bekommt eine eigene Firma und sieht nichts von
/// deiner (der Server prüft das). Das Passwort legst du fest; der Benutzer
/// ändert es später im Konto.
class UserCreateScreen extends ConsumerStatefulWidget {
  const UserCreateScreen({this.startWithNewCompany = false, super.key});

  /// „Neue Firma“ gleich vorwählen (nur für den Superadmin wirksam).
  final bool startWithNewCompany;

  @override
  ConsumerState<UserCreateScreen> createState() => _UserCreateScreenState();
}

class _UserCreateScreenState extends ConsumerState<UserCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _company = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final bool _isSuperadmin;
  late bool _newCompany;
  bool _busy = false;
  AppError? _error;

  @override
  void initState() {
    super.initState();
    _isSuperadmin = ref.read(sessionControllerProvider).isSuperadmin;
    _newCompany = _isSuperadmin && widget.startWithNewCompany;
  }

  @override
  void dispose() {
    _company.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final strings = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(usersRepositoryProvider)
        .createUser(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          company: _newCompany ? _company.text.trim() : null,
        );
    if (!mounted) return;
    switch (result) {
      case Success():
        showSuccessSnack(
          context,
          _newCompany ? strings.companyUserCreated : strings.userCreated,
        );
        UnsavedChangesGuard.disarm(context);
        context.pop();
      case Failure(:final error):
        setState(() {
          _busy = false;
          _error = error;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AppScreen(
      title: strings.newUser,
      children: [
        const SizedBox(height: AppSpacing.sm),
        // Die Wahl sehen nur Superadmins; für alle anderen bleibt es beim
        // Anlegen in der eigenen Firma.
        if (_isSuperadmin) ...[
          ChoiceChips<bool>(
            selected: _newCompany,
            onSelected: (value) => setState(() => _newCompany = value),
            options: [
              (value: false, label: strings.userForMyCompany),
              (value: true, label: strings.userNewCompany),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Text(
          _newCompany ? strings.newCompanyUserHint : strings.newUserHint,
          style: AppText.label,
        ),
        const SizedBox(height: AppSpacing.md),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_newCompany) ...[
                TextFormField(
                  controller: _company,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: '${strings.companyName} *',
                  ),
                  validator: (value) => value?.trim().isEmpty ?? true
                      ? strings.requiredField
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: '${strings.accountName} *',
                ),
                validator: (value) => value?.trim().isEmpty ?? true
                    ? strings.requiredField
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: '${strings.email} *'),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)
                      ? null
                      : strings.requiredField;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _password,
                obscureText: true,
                autocorrect: false,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: '${strings.password} *',
                  helperText: strings.passwordTooShort,
                ),
                validator: (value) =>
                    (value?.length ?? 0) < 8 ? strings.passwordTooShort : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                NoticeBanner(
                  message: _error!.localized(strings),
                  kind: NoticeKind.error,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              StickyAction(
                child: PrimaryButton(
                  label: strings.createUser,
                  loading: _busy,
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
