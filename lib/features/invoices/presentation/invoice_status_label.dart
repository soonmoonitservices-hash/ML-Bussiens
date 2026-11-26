import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/features/invoices/domain/invoice.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/display/status_label.dart';

/// Statuswort einer Rechnung: Offen grau, Bezahlt grün, Überfällig und
/// Storniert rot, Entwurf orange.
class InvoiceStatusLabel extends StatelessWidget {
  const InvoiceStatusLabel(this.status, {super.key});

  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return switch (status) {
      InvoiceStatus.draft => StatusLabel(
        strings.statusDraft,
        color: AppColors.warning,
        surface: AppColors.warningSurface,
      ),
      InvoiceStatus.open => StatusLabel(strings.statusOpenInvoice),
      InvoiceStatus.paid => StatusLabel(
        strings.statusPaid,
        color: AppColors.success,
        surface: AppColors.successSurface,
      ),
      InvoiceStatus.overdue => StatusLabel(
        strings.statusOverdue,
        color: AppColors.error,
        surface: AppColors.errorSurface,
      ),
      InvoiceStatus.cancelled => StatusLabel(
        strings.statusCancelled,
        color: AppColors.error,
        surface: AppColors.errorSurface,
      ),
    };
  }
}
