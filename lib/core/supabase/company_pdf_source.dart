import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_company_header.dart';

/// Liest die Firmendaten und das Logo für Briefkopf und Fußzeile der PDFs.
final class CompanyPdfSource {
  const CompanyPdfSource(this._client);

  final SupabaseClient _client;

  static const _columns =
      'name,address,phone,email,tax_number,vat_id,iban,bic,bank_name,'
      'managing_director,logo_path,invoice_footer,small_business_note,signature_path,signature_on_delivery_note,signature_on_invoice,signature_scale';

  Future<Result<PdfCompany>> load() => guard(() async {
    final row = await _client
        .from('company_settings')
        .select(_columns)
        .single();
    Uint8List? logo;
    final logoPath = row['logo_path'] as String?;
    if (logoPath != null && logoPath.isNotEmpty) {
      try {
        logo = await _client.storage.from('logos').download(logoPath);
      } on Object {
        logo = null; // Ohne Logo drucken ist besser als gar nicht.
      }
    }
    final onNote = row['signature_on_delivery_note'] as bool? ?? true;
    final onInvoice = row['signature_on_invoice'] as bool? ?? true;
    Uint8List? signature;
    final signaturePath = row['signature_path'] as String?;
    if (signaturePath != null && signaturePath.isNotEmpty) {
      try {
        signature = await _client.storage
            .from('signatures')
            .download(signaturePath);
      } on Object {
        signature = null;
      }
    }
    String? text(String key) {
      final value = (row[key] as String?)?.trim() ?? '';
      return value.isEmpty ? null : value;
    }

    return PdfCompany(
      name: row['name'] as String,
      address: row['address'] as String,
      phone: text('phone'),
      email: text('email'),
      taxNumber: text('tax_number'),
      vatId: text('vat_id'),
      iban: text('iban'),
      bic: text('bic'),
      bankName: text('bank_name'),
      managingDirector: text('managing_director'),
      logo: logo,
      signature: signature,
      signatureOnDeliveryNote: onNote,
      signatureOnInvoice: onInvoice,
      signatureScale: (row['signature_scale'] as int?) ?? 100,
      footerText: text('invoice_footer'),
      smallBusinessNote: text('small_business_note'),
    );
  });
}
