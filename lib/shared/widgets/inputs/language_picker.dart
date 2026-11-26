import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/preferences/locale_provider.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/inputs/filter_bar.dart';

/// Sprachwahl: Gerät, Deutsch oder Arabisch. Wirkt sofort und bleibt
/// gespeichert. Die Namen der Sprachen stehen immer in ihrer eigenen Schrift.
class LanguagePicker extends ConsumerWidget {
  const LanguagePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final selected = ref.watch(localeProvider)?.languageCode ?? '';
    return FilterBar<String>(
      selected: selected,
      onSelected: (code) => unawaited(
        ref.read(localeProvider.notifier).select(code.isEmpty ? null : code),
      ),
      options: [
        (value: '', label: strings.languageDevice),
        (value: 'de', label: 'Deutsch'),
        (value: 'ar', label: 'العربية'),
      ],
    );
  }
}
