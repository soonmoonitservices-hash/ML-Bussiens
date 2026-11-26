import 'package:flutter_test/flutter_test.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';
import 'package:warenbestand/features/delivery_notes/pdf/delivery_note_pdf.dart';

import '../../../helpers/pdf_test_data.dart';

DeliveryNotePdfData data(int count, {bool signed = true}) =>
    DeliveryNotePdfData(
      company: testCompany(),
      recipient: testRecipient,
      number: 'LS-2026-001',
      date: DateTime(2026, 11, 16),
      tourNumber: 'T-2026-012',
      items: [
        for (var i = 0; i < count; i++)
          DeliveryNotePdfItem(
            name: i.isEven
                ? 'Grüne Oliven mit einem sehr langen Namen $i'
                : 'Baladi-Käse $i',
            quantity: i.isEven
                ? const Quantity(55, ProductUnit.jar)
                : const Quantity(12500, ProductUnit.kg),
            unitsPerCarton: i.isEven ? 4 : null,
          ),
      ],
      signature: signed
          ? DeliveryNoteSignature(
              image: tinyPng,
              signerName: 'Ali Kaya',
              signedAt: DateTime(2026, 11, 16, 14, 5),
            )
          : null,
    );

void main() {
  final fonts = loadTestFonts();

  test('erzeugt ein PDF mit 1 Position', () async {
    final pdf = await DeliveryNotePdf.generate(data(1), fonts);
    expect(isPdf(pdf), isTrue);
    expect(pageCount(pdf), 1);
  });

  test('erzeugt ein mehrseitiges PDF mit 60 Positionen', () async {
    final pdf = await DeliveryNotePdf.generate(data(60), fonts);
    expect(isPdf(pdf), isTrue);
    expect(pageCount(pdf), greaterThan(1));
  });

  test('erzeugt einen Entwurf ohne Unterschrift', () async {
    final pdf = await DeliveryNotePdf.generate(data(3, signed: false), fonts);
    expect(isPdf(pdf), isTrue);
  });
}
