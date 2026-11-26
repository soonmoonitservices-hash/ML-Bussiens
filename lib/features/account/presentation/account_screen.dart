import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/supabase/providers.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/buttons/primary_button.dart';
import 'package:warenbestand/shared/widgets/buttons/secondary_button.dart';
import 'package:warenbestand/shared/widgets/dialogs/app_snack.dart';
import 'package:warenbestand/shared/widgets/dialogs/confirm_dialog.dart';
import 'package:warenbestand/shared/widgets/display/key_value_row.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';
import 'package:warenbestand/shared/widgets/display/section_header.dart';
import 'package:warenbestand/shared/widgets/inputs/language_picker.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';

/// Eigenes Konto: Name, Rolle, Passwort ändern, Abmelden, Konto löschen.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _name = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  AppError? _error;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _name.text = ref.read(sessionControllerProvider).profile?.name ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(
    Future<Result<void>> Function() action,
    String? success,
  ) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Success():
        if (success != null) showSuccessSnack(context, success);
      case Failure(:final error):
        setState(() => _error = error);
    }
  }

  Future<void> _saveName() async {
    final strings = AppLocalizations.of(context);
    final session = ref.read(sessionControllerProvider);
    final id = session.profile!.id;
    if (_name.text.trim().isEmpty) return;
    await _run(() async {
      final result = await ref
          .read(usersRepositoryProvider)
          .rename(id, _name.text);
      if (result is Success<void>) await session.refresh();
      return result;
    }, strings.nameSaved);
  }

  Future<void> _savePassword() async {
    final strings = AppLocalizations.of(context);
    if (_password.text.length < 8) {
      setState(() => _passwordError = strings.passwordTooShort);
      return;
    }
    setState(() => _passwordError = null);
    await _run(
      () => ref.read(authRepositoryProvider).updatePassword(_password.text),
      strings.passwordChanged,
    );
    _password.clear();
  }

  Future<void> _deleteAccount() async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: strings.deleteAccountTitle,
      message: strings.deleteAccountMessage,
      confirmLabel: strings.deleteAccount,
    );
    if (!confirmed || !mounted) return;
    final repository = ref.read(usersRepositoryProvider);
    await _run(() async {
      final result = await repository.deleteOwnAccount();
      if (result is Success<void>) {
        await ref.read(authRepositoryProvider).signOut();
      }
      return result;
    }, null);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final profile = ref.watch(sessionControllerProvider).profile;
    return AppScreen(
      title: strings.account,
      children: [
        if (_error != null) ...[
          NoticeBanner(
            message: _error!.localized(strings),
            kind: NoticeKind.error,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        KeyValueRow(label: strings.email, value: profile?.email ?? '—'),
        KeyValueRow(
          label: strings.role,
          value: (profile?.isChef ?? false)
              ? strings.roleChef
              : strings.roleOffice,
        ),
        SectionHeader(strings.accountName),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(labelText: strings.accountName),
          onSubmitted: (_) => _saveName(),
        ),
        const SizedBox(height: AppSpacing.sm),
        SecondaryButton(
          label: strings.save,
          onPressed: _busy ? null : _saveName,
        ),
        SectionHeader(strings.changePassword),
        TextField(
          controller: _password,
          obscureText: true,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: strings.newPassword,
            errorText: _passwordError,
          ),
          onSubmitted: (_) => _savePassword(),
        ),
        const SizedBox(height: AppSpacing.sm),
        SecondaryButton(
          label: strings.savePassword,
          onPressed: _busy ? null : _savePassword,
        ),
        SectionHeader(strings.language),
        const LanguagePicker(),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: strings.logout,
          onPressed: () =>
              unawaited(ref.read(authRepositoryProvider).signOut()),
        ),
        const SizedBox(height: AppSpacing.xxl),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
          ),
          onPressed: _busy ? null : _deleteAccount,
          child: Text(strings.deleteAccount),
        ),
      ],
    );
  }
}
