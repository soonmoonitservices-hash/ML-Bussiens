import 'dart:typed_data';

import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/pdf/pdf_file_cache.dart';
import 'package:warenbestand/core/pdf/pdf_file_name.dart';
import 'package:warenbestand/core/pdf/pdf_theme.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_address_window.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_company_header.dart';
import 'package:warenbestand/core/supabase/company_pdf_source.dart';
import 'package:warenbestand/features/delivery_notes/data/delivery_notes_repository.dart';
import 'package:warenbestand/features/delivery_notes/domain/delivery_note.dart';
import 'package:warenbestand/features/delivery_notes/pdf/delivery_note_pdf.dart';

/// Erzeugt, speichert und öffnet die PDFs der Lieferscheine.
///
/// Gespeichert wird nur der unterschriebene Lieferschein (Bucket `documents`,
/// Pfad `{jahr}/delivery-notes/{nummer}.pdf`); später wird immer dieses PDF
/// geöffnet. Entwürfe werden bei Bedarf neu erzeugt.
final class DeliveryNoteDocuments {
  DeliveryNoteDocuments({
    required this._repository,
    required this._company,
    required this._loadFonts,
  });

  final DeliveryNotesRepository _repository;
  final CompanyPdfSource _company;
  final Future<PdfFontBytes> Function() _loadFonts;
  PdfFontBytes? _fonts;

  /// Dateiname für Teilen und Speichern.
  static String fileName(DeliveryNote note) => PdfFileName.deliveryNote(
    number: note.number,
    recipient: note.recipientName,
  );

  static String _storagePath(DeliveryNote note) => PdfFileName.storagePath(
    year: note.date.year,
    type: 'delivery-notes',
    number: note.number,
  );

  /// PDF zum Ansehen: das gespeicherte, sonst frisch erzeugt (Entwurf mit
  /// Wasserzeichen). Ein unterschriebener Lieferschein ohne gespeichertes PDF
  /// wird dabei nachträglich abgelegt.
  Future<Result<Uint8List>> open(
    DeliveryNote note,
    List<DeliveryNoteItem> items,
  ) async {
    final storedPath = note.pdfPath;
    if (storedPath != null) {
      final cached = await PdfFileCache.read(storedPath);
      if (cached != null) return Success(cached);
      final stored = await _repository.downloadPdf(storedPath);
      if (stored is Success<Uint8List>) {
        await PdfFileCache.write(storedPath, stored.value);
        return stored;
      }
    }
    Uint8List? signature;
    if (note.isSigned && note.signaturePath != null) {
      final download = await _repository.downloadSignature(note.signaturePath!);
      switch (download) {
        case Success(:final value):
          signature = value;
        case Failure(:final error):
          return Failure(error);
      }
    }
    final rendered = await render(note, items, signature: signature);
    if (rendered is Success<Uint8List> && note.isSigned) {
      await _repository.storePdf(
        note: note,
        path: _storagePath(note),
        pdf: rendered.value,
      );
    }
    return rendered;
  }

  /// Erzeugt das PDF; ohne [signature] mit Wasserzeichen „ENTWURF“.
  Future<Result<Uint8List>> render(
    DeliveryNote note,
    List<DeliveryNoteItem> items, {
    Uint8List? signature,
  }) => guard(() async {
    final company = await _company.load();
    if (company is Failure<PdfCompany>) throw StateError(company.error.message);
    _fonts ??= await _loadFonts();
    final data = DeliveryNotePdfData(
      company: (company as Success<PdfCompany>).value,
      recipient: PdfRecipient(
        name: note.recipientName,
        address: note.recipientAddress,
      ),
      number: note.number,
      date: note.date,
      tourNumber: note.tourNumber,
      note: note.note,
      items: [
        for (final item in items)
          DeliveryNotePdfItem(
            name: item.name,
            quantity: item.quantity,
            unitsPerCarton: item.unitsPerCarton,
          ),
      ],
      signature: signature != null && note.signedAt != null
          ? DeliveryNoteSignature(
              image: signature,
              signerName: note.signerName ?? '',
              signedAt: note.signedAt!,
            )
          : null,
    );
    return await DeliveryNotePdf.generate(data, _fonts!);
  });

  /// Nach dem Unterschreiben: PDF mit Unterschrift erzeugen und ablegen.
  Future<Result<Uint8List>> storeSigned(
    DeliveryNote signedNote,
    List<DeliveryNoteItem> items,
    Uint8List signature,
  ) async {
    final rendered = await render(signedNote, items, signature: signature);
    if (rendered case Success(:final value)) {
      final stored = await _repository.storePdf(
        note: signedNote,
        path: _storagePath(signedNote),
        pdf: value,
      );
      if (stored case Failure(:final error)) return Failure(error);
    }
    return rendered;
  }
}
