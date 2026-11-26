import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/supabase/providers.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/features/drivers/domain/driver.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/buttons/primary_button.dart';
import 'package:warenbestand/shared/widgets/buttons/secondary_button.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';
import 'package:warenbestand/shared/widgets/layout/sticky_action.dart';
import 'package:warenbestand/shared/widgets/layout/unsaved_changes_guard.dart';

class DriverFormScreen extends ConsumerStatefulWidget {
  const DriverFormScreen({this.driverId, super.key});

  final String? driverId;

  @override
  ConsumerState<DriverFormScreen> createState() => _DriverFormScreenState();
}

class _DriverFormScreenState extends ConsumerState<DriverFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _vehicle = TextEditingController();
  Driver? _driver;
  bool _loading = false;
  AppError? _error;

  bool get _editing => widget.driverId != null;

  @override
  void initState() {
    super.initState();
    if (_editing) unawaited(_load());
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _vehicle.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ref
        .read(driversRepositoryProvider)
        .getById(widget.driverId!);
    if (!mounted) return;
    switch (result) {
      case Success(value: final driver):
        _driver = driver;
        _name.text = driver.name;
        _phone.text = driver.phone ?? '';
        _vehicle.text = driver.vehicle ?? '';
        setState(() {
          _loading = false;
        });
      case Failure(:final error):
        setState(() {
          _loading = false;
          _error = error;
        });
    }
  }

  DriverInput get _input => DriverInput(
    name: _name.text,
    phone: _phone.text,
    vehicle: _vehicle.text,
    active: _driver?.active ?? true,
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final repository = ref.read(driversRepositoryProvider);
    final result = _editing
        ? await repository.update(
            id: _driver!.id,
            loadedUpdatedAt: _driver!.updatedAt,
            input: _input,
          )
        : await repository.create(_input);
    await _handleResult(result);
  }

  Future<void> _toggleActive() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ref
        .read(driversRepositoryProvider)
        .setActive(_driver!, !_driver!.active);
    await _handleResult(result);
  }

  Future<void> _handleResult(Result<Driver> result) async {
    if (!mounted) return;
    switch (result) {
      case Success():
        UnsavedChangesGuard.disarm(context);
        context.pop();
      case Failure(:final error):
        setState(() {
          _loading = false;
          _error = error;
        });
        if (error is ConflictError) await _showConflict(error);
    }
  }

  Future<void> _showConflict(ConflictError error) async {
    final strings = AppLocalizations.of(context);
    await showAdaptiveDialog<void>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        content: Text(error.localized(strings)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              unawaited(_load());
            },
            child: Text(strings.reload),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AppScreen(
      title: _editing ? strings.editDriver : strings.newDriver,
      children: [
        const SizedBox(height: AppSpacing.sm),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: strings.driverName),
                validator: (value) => value?.trim().isEmpty ?? true
                    ? strings.requiredField
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: strings.phone),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _vehicle,
                decoration: InputDecoration(labelText: strings.vehicle),
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
                  label: strings.save,
                  loading: _loading,
                  onPressed: _save,
                ),
              ),
              if (_driver != null) ...[
                const SizedBox(height: AppSpacing.sm),
                SecondaryButton(
                  label: _driver!.active
                      ? strings.deactivate
                      : strings.reactivate,
                  onPressed: _loading ? null : _toggleActive,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
