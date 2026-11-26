import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/supabase/providers.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/features/company/domain/company_settings.dart';
import 'package:warenbestand/features/company/presentation/company_signature_pad.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/buttons/primary_button.dart';
import 'package:warenbestand/shared/widgets/buttons/secondary_button.dart';
import 'package:warenbestand/shared/widgets/dialogs/app_snack.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';
import 'package:warenbestand/shared/widgets/display/skeleton_list.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';
import 'package:warenbestand/shared/widgets/layout/sticky_action.dart';

/// Firmendaten für Briefkopf und Rechnungen. Nur der Chef ändert sie.
class CompanyScreen extends ConsumerStatefulWidget {
  const CompanyScreen({super.key});

  @override
  ConsumerState<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends ConsumerState<CompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{
    for (final key in _textKeys) key: TextEditingController(),
  };
  static const _textKeys = [
    'name',
    'address',
    'phone',
    'email',
    'taxNumber',
    'vatId',
    'iban',
    'bic',
    'bankName',
    'managingDirector',
    'paymentTermDays',
    'invoiceFooter',
    'smallBusinessNote',
  ];
  bool _cashIncludesVat = false;
  bool _smallBusiness = false;
  bool _signatureOnNote = true;
  bool _signatureOnInvoice = true;
  int _signatureScale = 100;
  String? _signaturePath;
  Uint8List? _signatureImage;
  bool _signatureBusy = false;
  bool _loaded = false;
  bool _saving = false;
  AppError? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _text(String key) => _controllers[key]!.text;

  Future<void> _load() async {
    final result = await ref.read(companyRepositoryProvider).load();
    if (!mounted) return;
    switch (result) {
      case Success(:final value):
        _controllers['name']!.text = value.name;
        _controllers['address']!.text = value.address;
        _controllers['phone']!.text = value.phone;
        _controllers['email']!.text = value.email;
        _controllers['taxNumber']!.text = value.taxNumber;
        _controllers['vatId']!.text = value.vatId;
        _controllers['iban']!.text = value.iban;
        _controllers['bic']!.text = value.bic;
        _controllers['bankName']!.text = value.bankName;
        _controllers['managingDirector']!.text = value.managingDirector;
        _controllers['paymentTermDays']!.text = '${value.paymentTermDays}';
        _controllers['invoiceFooter']!.text = value.invoiceFooter;
        _controllers['smallBusinessNote']!.text = value.smallBusinessNote;
        setState(() {
          _cashIncludesVat = value.cashIncludesVat;
          _smallBusiness = value.isSmallBusiness;
          _signatureOnNote = value.signatureOnDeliveryNote;
          _signatureOnInvoice = value.signatureOnInvoice;
          _signatureScale = value.signatureScale;
          _signaturePath = value.signaturePath;
          _loaded = true;
        });
        unawaited(_loadSignatureImage());
      case Failure(:final error):
        setState(() => _error = error);
    }
  }

  Future<void> _loadSignatureImage() async {
    final path = _signaturePath;
    if (path == null || path.isEmpty) {
      setState(() => _signatureImage = null);
      return;
    }
    final result = await ref
        .read(companyRepositoryProvider)
        .downloadSignature(path);
    if (!mounted) return;
    setState(
      () =>
          _signatureImage = result is Success<Uint8List> ? result.value : null,
    );
  }

  Future<void> _drawSignature() async {
    final png = await showCompanySignaturePad(context);
    if (png == null || !mounted) return;
    await _changeSignature(
      () => ref.read(companyRepositoryProvider).saveSignature(png),
      AppLocalizations.of(context).companySignatureSaved,
    );
  }

  Future<void> _deleteSignature() => _changeSignature(
    () => ref.read(companyRepositoryProvider).removeSignature(),
    AppLocalizations.of(context).companySignatureDeleted,
  );

  Future<void> _changeSignature(
    Future<Result<void>> Function() action,
    String done,
  ) async {
    setState(() {
      _signatureBusy = true;
      _error = null;
    });
    final result = await action();
    if (!mounted) return;
    switch (result) {
      case Success():
        final fresh = await ref.read(companyRepositoryProvider).load();
        if (!mounted) return;
        if (fresh case Success(:final value)) {
          _signaturePath = value.signaturePath;
        }
        await _loadSignatureImage();
        if (!mounted) return;
        setState(() => _signatureBusy = false);
        showSuccessSnack(context, done);
      case Failure(:final error):
        setState(() {
          _signatureBusy = false;
          _error = error;
        });
    }
  }

  Widget _signatureSection(AppLocalizations strings, {required bool isChef}) {
    final image = _signatureImage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(strings.companySignature, style: AppText.label),
        const SizedBox(height: AppSpacing.sm),
        Container(
          height: 120,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.inkMuted),
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          child: image == null
              ? Text(strings.companySignatureNone, style: AppText.label)
              : Image.memory(
                  image,
                  fit: BoxFit.contain,
                  height: 120 * _signatureScale / 100,
                ),
        ),
        if (image != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(strings.signatureSize(_signatureScale), style: AppText.label),
          Row(
            children: [
              IconButton(
                tooltip: strings.signatureSmaller,
                onPressed: isChef && _signatureScale > 50
                    ? () => setState(() => _signatureScale -= 10)
                    : null,
                icon: const Icon(AppIcons.minus),
              ),
              Expanded(
                child: Slider(
                  value: _signatureScale.toDouble(),
                  min: 50,
                  max: 200,
                  divisions: 15,
                  label: '$_signatureScale %',
                  onChanged: isChef
                      ? (v) => setState(() => _signatureScale = v.round())
                      : null,
                ),
              ),
              IconButton(
                tooltip: strings.signatureLarger,
                onPressed: isChef && _signatureScale < 200
                    ? () => setState(() => _signatureScale += 10)
                    : null,
                icon: const Icon(AppIcons.add),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        if (isChef) ...[
          SecondaryButton(
            label: image == null
                ? strings.companySignatureDraw
                : strings.companySignatureRedraw,
            onPressed: _signatureBusy ? null : _drawSignature,
          ),
          if (_signaturePath != null) ...[
            const SizedBox(height: AppSpacing.xs),
            SecondaryButton(
              label: strings.companySignatureDelete,
              icon: AppIcons.delete,
              onPressed: _signatureBusy ? null : _deleteSignature,
            ),
          ],
        ],
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(strings.signatureOnDeliveryNote),
          value: _signatureOnNote,
          onChanged: isChef
              ? (v) => setState(() => _signatureOnNote = v)
              : null,
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final settings = CompanySettings(
      name: _text('name'),
      address: _text('address'),
      phone: _text('phone'),
      email: _text('email'),
      taxNumber: _text('taxNumber'),
      vatId: _text('vatId'),
      iban: _text('iban'),
      bic: _text('bic'),
      bankName: _text('bankName'),
      managingDirector: _text('managingDirector'),
      paymentTermDays: int.parse(_text('paymentTermDays').trim()),
      invoiceFooter: _text('invoiceFooter'),
      cashIncludesVat: _cashIncludesVat,
      isSmallBusiness: _smallBusiness,
      smallBusinessNote: _text('smallBusinessNote'),
      signaturePath: _signaturePath,
      signatureOnDeliveryNote: _signatureOnNote,
      signatureOnInvoice: _signatureOnInvoice,
      signatureScale: _signatureScale,
      updatedAt: '',
    );
    final result = await ref.read(companyRepositoryProvider).save(settings);
    if (!mounted) return;
    final strings = AppLocalizations.of(context);
    switch (result) {
      case Success():
        showSuccessSnack(context, strings.companySaved);
        setState(() => _saving = false);
      case Failure(:final error):
        setState(() {
          _saving = false;
          _error = error;
        });
    }
  }

  Widget _field(
    String key,
    String label, {
    bool required = false,
    TextInputType? keyboard,
    int maxLines = 1,
    TextCapitalization capitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    final strings = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: _controllers[key],
        keyboardType: keyboard,
        maxLines: maxLines,
        minLines: 1,
        textCapitalization: capitalization,
        textInputAction: maxLines > 1
            ? TextInputAction.newline
            : TextInputAction.next,
        decoration: InputDecoration(labelText: required ? '$label *' : label),
        validator:
            validator ??
            (value) => required && (value?.trim().isEmpty ?? true)
                ? strings.requiredField
                : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final isChef = ref.watch(sessionControllerProvider).canManage;
    return AppScreen(
      title: strings.company,
      children: [
        if (_error != null) ...[
          NoticeBanner(
            message: _error!.localized(strings),
            kind: NoticeKind.error,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (!_loaded && _error == null)
          const SkeletonList()
        else if (_loaded)
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isChef) ...[
                  NoticeBanner(
                    message: strings.companyOnlyChef,
                    kind: NoticeKind.warning,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                _field(
                  'name',
                  strings.companyName,
                  required: true,
                  capitalization: TextCapitalization.words,
                ),
                _field(
                  'address',
                  strings.companyAddress,
                  required: true,
                  maxLines: 3,
                  capitalization: TextCapitalization.words,
                ),
                _field('phone', strings.phone, keyboard: TextInputType.phone),
                _field(
                  'email',
                  strings.email,
                  keyboard: TextInputType.emailAddress,
                ),
                _field('managingDirector', strings.managingDirector),
                _field('taxNumber', strings.taxNumber),
                _field('vatId', strings.vatId),
                _field('iban', strings.iban),
                _field('bic', strings.bic),
                _field('bankName', strings.bankName),
                _field(
                  'paymentTermDays',
                  strings.paymentTermDays,
                  required: true,
                  keyboard: TextInputType.number,
                  validator: (value) {
                    final days = int.tryParse(value?.trim() ?? '');
                    return days == null || days < 0
                        ? strings.requiredField
                        : null;
                  },
                ),
                _field('invoiceFooter', strings.invoiceFooter, maxLines: 3),
                const SizedBox(height: AppSpacing.md),
                _signatureSection(strings, isChef: isChef),
                const SizedBox(height: AppSpacing.lg),
                if (isChef)
                  StickyAction(
                    child: PrimaryButton(
                      label: strings.save,
                      loading: _saving,
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
