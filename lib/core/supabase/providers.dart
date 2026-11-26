import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warenbestand/core/drafts/form_drafts.dart';
import 'package:warenbestand/core/media/photo_service.dart';
import 'package:warenbestand/core/pdf/pdf_theme.dart';
import 'package:warenbestand/core/preferences/app_preferences.dart';
import 'package:warenbestand/core/supabase/company_pdf_source.dart';
import 'package:warenbestand/features/auth/data/auth_repository.dart';
import 'package:warenbestand/features/auth/presentation/session_controller.dart';
import 'package:warenbestand/features/company/data/company_repository.dart';
import 'package:warenbestand/features/delivery_notes/data/delivery_note_documents.dart';
import 'package:warenbestand/features/delivery_notes/data/delivery_notes_repository.dart';
import 'package:warenbestand/features/drivers/data/drivers_repository.dart';
import 'package:warenbestand/features/invoices/data/invoice_documents.dart';
import 'package:warenbestand/features/invoices/data/invoices_repository.dart';
import 'package:warenbestand/features/platform/data/platform_repository.dart';
import 'package:warenbestand/features/products/data/products_repository.dart';
import 'package:warenbestand/features/receipts/data/expense_documents.dart';
import 'package:warenbestand/features/receipts/data/expenses_repository.dart';
import 'package:warenbestand/features/reports/data/report_documents.dart';
import 'package:warenbestand/features/reports/data/reports_repository.dart';
import 'package:warenbestand/features/tours/data/tour_goods_documents.dart';
import 'package:warenbestand/features/tours/data/tours_repository.dart';
import 'package:warenbestand/features/users/data/users_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

/// Angefangene Formulare dieses Geräts (je Benutzer getrennt).
final formDraftsProvider = Provider<FormDrafts>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return FormDrafts(
    ref.watch(appPreferencesProvider),
    () => client.auth.currentUser?.id,
  );
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);

final sessionControllerProvider = Provider<SessionController>((ref) {
  final controller = SessionController(ref.watch(authRepositoryProvider));
  ref.onDispose(controller.dispose);
  return controller;
});

final driversRepositoryProvider = Provider<DriversRepository>(
  (ref) => DriversRepository(ref.watch(supabaseClientProvider)),
);

final productsRepositoryProvider = Provider<ProductsRepository>(
  (ref) => ProductsRepository(ref.watch(supabaseClientProvider)),
);

final toursRepositoryProvider = Provider<ToursRepository>(
  (ref) => ToursRepository(ref.watch(supabaseClientProvider)),
);

final companyPdfSourceProvider = Provider<CompanyPdfSource>(
  (ref) => CompanyPdfSource(ref.watch(supabaseClientProvider)),
);

final deliveryNotesRepositoryProvider = Provider<DeliveryNotesRepository>(
  (ref) => DeliveryNotesRepository(ref.watch(supabaseClientProvider)),
);

final deliveryNoteDocumentsProvider = Provider<DeliveryNoteDocuments>(
  (ref) => DeliveryNoteDocuments(
    repository: ref.watch(deliveryNotesRepositoryProvider),
    company: ref.watch(companyPdfSourceProvider),
    loadFonts: PdfFontBytes.fromAssets,
  ),
);

final expensesRepositoryProvider = Provider<ExpensesRepository>(
  (ref) => ExpensesRepository(ref.watch(supabaseClientProvider)),
);

final photoServiceProvider = Provider<PhotoService>(
  (ref) => const PhotoService(),
);

final expenseDocumentsProvider = Provider<ExpenseDocuments>(
  (ref) => ExpenseDocuments(
    repository: ref.watch(expensesRepositoryProvider),
    company: ref.watch(companyPdfSourceProvider),
    loadFonts: PdfFontBytes.fromAssets,
  ),
);

final invoicesRepositoryProvider = Provider<InvoicesRepository>(
  (ref) => InvoicesRepository(ref.watch(supabaseClientProvider)),
);

final invoiceDocumentsProvider = Provider<InvoiceDocuments>(
  (ref) => InvoiceDocuments(
    repository: ref.watch(invoicesRepositoryProvider),
    company: ref.watch(companyPdfSourceProvider),
    loadFonts: PdfFontBytes.fromAssets,
  ),
);

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepository(ref.watch(supabaseClientProvider)),
);

final reportDocumentsProvider = Provider<ReportDocuments>(
  (ref) => ReportDocuments(
    company: ref.watch(companyPdfSourceProvider),
    loadFonts: PdfFontBytes.fromAssets,
  ),
);

final companyRepositoryProvider = Provider<CompanyRepository>(
  (ref) => CompanyRepository(ref.watch(supabaseClientProvider)),
);

final usersRepositoryProvider = Provider<UsersRepository>(
  (ref) => UsersRepository(ref.watch(supabaseClientProvider)),
);

final platformRepositoryProvider = Provider<PlatformRepository>(
  (ref) => PlatformRepository(ref.watch(supabaseClientProvider)),
);

final tourGoodsDocumentsProvider = Provider<TourGoodsDocuments>(
  (ref) => TourGoodsDocuments(
    company: ref.watch(companyPdfSourceProvider),
    loadFonts: PdfFontBytes.fromAssets,
  ),
);
