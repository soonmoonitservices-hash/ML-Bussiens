import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:warenbestand/core/formatting/date_formatter.dart';
import 'package:warenbestand/core/formatting/quantity_formatter.dart';
import 'package:warenbestand/core/pdf/pdf_service.dart';
import 'package:warenbestand/core/pdf/pdf_theme.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_address_window.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_company_header.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_doc_meta.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_items_table.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_note_block.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_signature_block.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';

/// Eine Position des Lieferscheins (ohne Preise).
final class DeliveryNotePdfItem {
  /// Erzeugt die Position.
  const DeliveryNotePdfItem({
    required this.name,
    required this.quantity,
    this.unitsPerCarton,
  });

  /// Artikelname (Kopie aus dem Lieferschein).
  final String name;

  /// Menge in Basiseinheit.
  final Quantity quantity;

  /// Inhalt pro Karton, falls Karton-Produkt.
  final int? unitsPerCarton;
}

/// Unterschrift des Empfängers.
final class DeliveryNoteSignature {
  /// Erzeugt die Unterschrift.
  const DeliveryNoteSignature({
    required this.image,
    required this.signerName,
    required this.signedAt,
  });

  /// Unterschriftsbild (PNG), vorher geladen.
  final Uint8List image;

  /// Name des Unterzeichners.
  final String signerName;

  /// Zeitpunkt (Europe/Berlin).
  final DateTime signedAt;
}

/// Alle Daten des Lieferscheins; das PDF greift nicht auf die Datenbank zu.
final class DeliveryNotePdfData {
  /// Erzeugt die Daten.
  const DeliveryNotePdfData({
    required this.company,
    required this.recipient,
    required this.number,
    required this.date,
    required this.items,
    this.tourNumber,
    this.note,
    this.signature,
  });

  /// Firmendaten.
  final PdfCompany company;

  /// Empfänger.
  final PdfRecipient recipient;

  /// Nummer (LS-2026-001).
  final String number;

  /// Lieferdatum.
  final DateTime date;

  /// Positionen.
  final List<DeliveryNotePdfItem> items;

  /// Tour-Nummer, falls zugeordnet.
  final String? tourNumber;

  /// Hinweis des Lieferscheins.
  final String? note;

  /// Unterschrift; ohne sie ist das PDF ein Entwurf.
  final DeliveryNoteSignature? signature;
}

/// Lieferschein ohne Preise, mit Unterschrift.
abstract final class DeliveryNotePdf {
  /// Erzeugt das PDF im Hintergrund.
  static Future<Uint8List> generate(
    DeliveryNotePdfData data,
    PdfFontBytes fonts,
  ) => PdfService.generate(builder: build, data: data, fonts: fonts);

  /// Baut das Dokument (läuft im Isolate).
  static pw.Document build(DeliveryNotePdfData data, PdfTheme theme) {
    final s = theme.strings;
    final rows = [
      for (var i = 0; i < data.items.length; i++)
        _row(data.items[i], i + 1, theme),
    ];
    return pw.Document(title: '${s.deliveryNote} ${data.number}')..addPage(
      PdfService.letterPage(
        theme: theme,
        company: data.company,
        recipient: data.recipient,
        body: [
          PdfDocMeta.build(
            theme,
            title: s.deliveryNote,
            fields: [
              (label: s.number, value: data.number),
              (label: s.deliveryDate, value: DateFormatter.date(data.date)),
              if (data.tourNumber != null)
                (label: s.tour, value: data.tourNumber!),
            ],
          ),
          ...PdfItemsTable.build(
            theme,
            columns: [
              PdfColumn.fixed(s.position, 12),
              PdfColumn.flex(s.article, flex: 3),
              PdfColumn.fixed(s.quantity, 22, alignEnd: true),
              PdfColumn.fixed(s.unit, 22),
            ],
            rows: rows,
            keepWithLastRow: [
              if (data.note != null && data.note!.isNotEmpty)
                PdfNoteBlock.build(theme, data.note!),
              PdfNoteBlock.build(theme, s.deliveryReceived),
              pw.Wrap(
                crossAxisAlignment: pw.WrapCrossAlignment.end,
                spacing: 12 * PdfTheme.mm,
                children: [
                  // Fahrer: leeres Feld, er unterschreibt nach dem Ausdruck von Hand.
                  PdfSignatureBlock.build(
                    theme,
                    caption: s.recipientSignature,
                    scale: data.company.signatureScale,
                  ),
                  // Inhaber: immer als Feld; mit der gespeicherten Unterschrift
                  // aus den Firmendaten, wenn sie dort gespeichert und für den
                  // Lieferschein eingeschaltet ist.
                  PdfSignatureBlock.build(
                    theme,
                    caption: s.ownerSignature(
                      data.company.managingDirector ?? data.company.name,
                    ),
                    image: data.company.signatureOnDeliveryNote
                        ? data.company.signature
                        : null,
                    scale: data.company.signatureScale,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static List<String> _row(
    DeliveryNotePdfItem item,
    int position,
    PdfTheme theme,
  ) {
    final breakdown = QuantityFormatter.cartonBreakdown(
      item.quantity,
      item.unitsPerCarton,
    );
    return [
      '$position',
      if (breakdown == null) item.name else '${item.name}\n= $breakdown',
      QuantityFormatter.formatNumber(item.quantity),
      theme.strings.quantityLabels.unitName(
        item.quantity.unit,
        item.quantity.base,
      ),
    ];
  }
}
