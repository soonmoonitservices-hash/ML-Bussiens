import 'package:flutter_test/flutter_test.dart';
import 'package:warenbestand/core/pdf/pdf_file_name.dart';

void main() {
  test('Lieferschein: Leerzeichen werden zu Bindestrichen', () {
    expect(
      PdfFileName.deliveryNote(
        number: 'LS-2026-001',
        recipient: 'Feinkost Kaya',
      ),
      'Lieferschein_LS-2026-001_Feinkost-Kaya.pdf',
    );
  });

  test('Rechnung und Stornorechnung', () {
    expect(
      PdfFileName.invoice(number: 'RE-2026-001', recipient: 'Feinkost Kaya'),
      'Rechnung_RE-2026-001_Feinkost-Kaya.pdf',
    );
    expect(
      PdfFileName.cancellationInvoice(number: 'RE-2026-005'),
      'Stornorechnung_RE-2026-005.pdf',
    );
  });

  test('Tourabrechnung mit Fahrer und Datum', () {
    expect(
      PdfFileName.tourSummary(
        number: 'T-2026-012',
        driver: 'Mehmet Yilmaz',
        date: DateTime(2026, 11, 16),
      ),
      'Tourabrechnung_T-2026-012_Mehmet-Yilmaz_2026-11-16.pdf',
    );
  });

  test('ausgewählte Belege mit Zeitraum', () {
    expect(
      PdfFileName.expensesSelection(
        from: DateTime(2026, 11, 5),
        to: DateTime(2026, 11, 23),
      ),
      'Belege_Auswahl_2026-11-05_bis_2026-11-23.pdf',
    );
  });

  test('Belege und Auswertung', () {
    expect(
      PdfFileName.expensesMonth(year: 2026, month: 11),
      'Belege_2026-11.pdf',
    );
    expect(
      PdfFileName.report(from: DateTime(2026, 11), to: DateTime(2026, 11, 30)),
      'Auswertung_2026-11-01_bis_2026-11-30.pdf',
    );
  });

  test('Umlaute und ß werden ersetzt', () {
    expect(
      PdfFileName.sanitize('Müller & Söhne Größe'),
      'Mueller-Soehne-Groesse',
    );
    expect(PdfFileName.sanitize('Äpfel Öl Übung'), 'Aepfel-Oel-Uebung');
  });

  test('Sonderzeichen entfallen, Bindestriche werden nicht doppelt', () {
    expect(PdfFileName.sanitize('  Café  "Zum / Löwen"  '), 'Cafe-Zum-Loewen');
    expect(PdfFileName.sanitize('a - - b'), 'a-b');
    expect(PdfFileName.sanitize('***'), '');
  });

  test('leerer Empfänger lässt den Teil weg', () {
    expect(
      PdfFileName.invoice(number: 'RE-2026-001', recipient: ''),
      'Rechnung_RE-2026-001.pdf',
    );
  });

  test('Speicherpfad im Bucket documents', () {
    expect(
      PdfFileName.storagePath(
        year: 2026,
        type: 'invoices',
        number: 'RE-2026-001',
      ),
      '2026/invoices/RE-2026-001.pdf',
    );
  });
}
