import 'package:flutter/painting.dart';
import 'package:warenbestand/core/theme/app_colors.dart';

/// Schriften und die fünf Größen der App: Seitentitel 28, Abschnitt 17,
/// Text 15, Beschriftung 13, große Beträge 32. Mehr Stufen gibt es nicht.
abstract final class AppText {
  /// Inter; Arabisch kommt über die Ersatzschrift.
  static const family = 'Inter';

  /// IBM Plex Sans Arabic, gleiche Familie und Proportionen.
  static const arabicFamily = 'IBMPlexSansArabic';

  /// IBM Plex Mono für Artikel-, Tour- und Rechnungsnummern.
  static const monoFamily = 'IBMPlexMono';

  static const _tabular = [FontFeature.tabularFigures()];

  static const _base = TextStyle(
    fontFamily: family,
    fontFamilyFallback: [arabicFamily],
    color: AppColors.ink,
    height: 1.35,
  );

  /// Seitentitel 28.
  static final TextStyle pageTitle = _base.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  /// Abschnittsüberschrift 17.
  static final TextStyle section = _base.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );

  /// Text 15.
  static final TextStyle body = _base.copyWith(fontSize: 15);

  /// Text 15, hervorgehoben.
  static final TextStyle bodyStrong = body.copyWith(
    fontWeight: FontWeight.w500,
  );

  /// Kleine Labels (Chips, Tabs) 12, Medium.
  static final TextStyle chip = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  /// Beschriftung 13, gedämpft.
  static final TextStyle label = _base.copyWith(
    fontSize: 13,
    color: AppColors.inkMuted,
  );

  /// Beträge und Mengen in Listen: Text 15 mit tabellarischen Ziffern.
  static final TextStyle amount = body.copyWith(
    fontWeight: FontWeight.w500,
    fontFeatures: _tabular,
  );

  /// Große Beträge 32.
  static final TextStyle amountLarge = _base.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    fontFeatures: _tabular,
    height: 1.15,
  );

  /// Nummern (Artikel, Tour, Rechnung): Plex Mono 13, grau.
  static const code = TextStyle(
    fontFamily: monoFamily,
    fontSize: 13,
    color: AppColors.inkMuted,
    height: 1.35,
  );
}
