import 'dart:typed_data';

import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/pdf/pdf_file_cache.dart';
import 'package:warenbestand/core/pdf/pdf_file_name.dart';
import 'package:warenbestand/core/pdf/pdf_theme.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_address_window.dart';
import 'package:warenbestand/core/supabase/company_pdf_source.dart';
import 'package:warenbestand/features/invoices/data/invoices_repository.dart';
import 'package:warenbestand/features/invoices/domain/invoice.dart';
import 'package:warenbestand/features/invoices/pdf/invoice_pdf.dart';

/// Erzeugt, speichert und öffnet die PDFs der Rechnungen.
///
/// Gespeichert wird nur die festgeschriebene Rechnung bzw. Storno (Bucket
/// `documents`, `{jahr}/invoices/{nummer}.pdf`); später wird immer dieses PDF
/// geöffnet. Entwürfe werden bei Bedarf mit Wasserzeichen neu erzeugt. Die
/// Summen kommen aus der Datenbank; das PDF rechnet nicht.
final class InvoiceDocuments {
  InvoiceDocuments({
    required this._repository,
    required this._company,
    required this._loadFonts,
  });

  final InvoicesRepository _repository;
  final CompanyPdfSource _company;
  final Future<PdfFontBytes> Function() _loadFonts;
  PdfFontBytes? _fonts;

  static String fileName(Invoice invoice) {
    final number = invoice.number ?? 'Entwurf';
    return invoice.isCancellation
        ? PdfFileName.cancellationInvoice(number: number)
        : PdfFileName.invoice(number: number, recipient: invoice.recipientName);
  }

  static String _storagePath(Invoice invoice) => PdfFileName.storagePath(
    year: invoice.date.year,
    type: 'invoices',
    number: invoice.number!,
  );

  /// PDF zum Ansehen: das gespeicherte, sonst frisch erzeugt. Eine
  /// festgeschriebene Rechnung ohne gespeichertes PDF wird nachträglich
  /// abgelegt.
  Future<Result<Uint8List>> open(
    Invoice invoice,
    List<InvoiceItem> items,
  ) async {
    final storedPath = invoice.pdfPath;
    if (storedPath != null) {
      final cached = await PdfFileCache.read(storedPath);
      if (cached != null) return Success(cached);
      final stored = await _repository.downloadPdf(storedPath);
      if (stored is Success<Uint8List>) {
        await PdfFileCache.write(storedPath, stored.value);
        return stored;
      }
    }
    final rendered = await render(invoice, items);
    if (rendered is Success<Uint8List> && !invoice.isDraft) {
      await _repository.storePdf(
        invoiceId: invoice.id,
        path: _storagePath(invoice),
        pdf: rendered.value,
      );
    }
    return rendered;
  }

  /// Nach dem Festschreiben bzw. Stornieren: PDF erzeugen und ablegen.
  Future<Result<Uint8List>> store(
    Invoice invoice,
    List<InvoiceItem> items,
  ) async {
    final rendered = await render(invoice, items);
    if (rendered case Success(:final value)) {
      final stored = await _repository.storePdf(
        invoiceId: invoice.id,
        path: _storagePath(invoice),
        pdf: value,
      );
      if (stored case Failure(:final error)) return Failure(error);
    }
    return rendered;
  }

  Future<Result<Uint8List>> render(Invoice invoice, List<InvoiceItem> items) =>
      guard(() async {
        final companyResult = await _company.load();
        final company = switch (companyResult) {
          Success(:final value) => value,
          Failure(:final error) => throw StateError(error.message),
        };
        String? cancelsNumber;
        if (invoice.cancelsInvoiceId != null) {
          final result = await _repository.numberOf(invoice.cancelsInvoiceId!);
          if (result case Success(:final value)) cancelsNumber = value;
        }
        _fonts ??= await _loadFonts();
        final vatId = invoice.recipientVatId;
        final data = InvoicePdfData(
          company: company,
          recipient: PdfRecipient(
            name: invoice.recipientName,
            address: [
              invoice.recipientAddress,
              if (vatId != null && vatId.isNotEmpty) 'USt-IdNr.: $vatId',
            ].join('\n'),
          ),
          number: invoice.number,
          date: invoice.date,
          serviceDate: invoice.serviceDate,
          dueDate: invoice.dueDate ?? invoice.date,
          deliveryNoteNumber: invoice.deliveryNoteNumber,
          cancelsInvoiceNumber: cancelsNumber,
          note: invoice.note,
          isSmallBusiness: invoice.isSmallBusiness,
          lines: [
            for (final item in items)
              InvoicePdfLine(
                name: item.name,
                quantity: item.quantity,
                priceNet: item.priceNet,
                vatRate: item.vatRate,
                lineNet: item.lineNet,
              ),
          ],
          net: invoice.net,
          vat7: invoice.vat7,
          vat19: invoice.vat19,
          gross: invoice.gross,
        );
        return await InvoicePdf.generate(data, _fonts!);
      });
}
