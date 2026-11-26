import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/formatting/money_formatter.dart';
import 'package:warenbestand/core/formatting/quantity_formatter.dart';
import 'package:warenbestand/core/supabase/providers.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/features/tours/data/tour_goods_documents.dart';
import 'package:warenbestand/features/tours/domain/goods_list.dart';
import 'package:warenbestand/features/tours/pdf/goods_list_pdf.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/l10n/quantity_labels.dart';
import 'package:warenbestand/shared/presentation/pdf_preview_screen.dart';
import 'package:warenbestand/shared/widgets/buttons/primary_button.dart';
import 'package:warenbestand/shared/widgets/dialogs/app_snack.dart';
import 'package:warenbestand/shared/widgets/display/app_list_row.dart';
import 'package:warenbestand/shared/widgets/display/empty_state.dart';
import 'package:warenbestand/shared/widgets/display/key_value_row.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';
import 'package:warenbestand/shared/widgets/layout/sticky_action.dart';

/// Was die Warenliste braucht: Art, Tour und die fertigen Zeilen.
final class GoodsListArgs {
  const GoodsListArgs({
    required this.kind,
    required this.tourNumber,
    required this.driverName,
    required this.date,
    required this.lines,
  });

  final GoodsListKind kind;
  final String tourNumber;
  final String driverName;
  final DateTime date;
  final List<GoodsLine> lines;
}

/// „Verkaufte Ware“ oder „Zurückgeholte Ware“ einer Tour: je Produkt Menge,
/// Einzelpreis und Gesamtpreis, dazu die Summe. Als PDF teilbar.
class GoodsListScreen extends ConsumerWidget {
  const GoodsListScreen({required this.args, super.key});

  final GoodsListArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final labels = strings.quantityLabels;
    final sold = args.kind == GoodsListKind.sold;
    final title = sold ? strings.soldGoods : strings.returnedGoods;
    final total = GoodsLists.total(args.lines);
    return AppScreen(
      title: title,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.xs,
          ),
          child: Text(
            '${args.tourNumber} · ${args.driverName}',
            style: AppText.label,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (args.lines.isEmpty)
          EmptyState(message: strings.noGoods)
        else ...[
          ...AppListRow.divided([
            for (final line in args.lines)
              AppListRow(
                title: line.name,
                subtitle:
                    '${QuantityFormatter.format(line.quantity, labels: labels)}'
                    ' × ${MoneyFormatter.format(line.unitPrice)}',
                trailing: Text(
                  MoneyFormatter.format(line.total),
                  style: AppText.amount,
                  textDirection: TextDirection.ltr,
                ),
              ),
          ]),
          KeyValueRow(
            label: strings.goodsTotal,
            value: MoneyFormatter.format(total),
            strong: true,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        StickyAction(
          child: PrimaryButton(
            label: strings.shareGoodsPdf,
            icon: AppIcons.pdf,
            onPressed: args.lines.isEmpty
                ? () => showErrorSnack(context, strings.pdfNothingToShow)
                : () {
                    final documents = ref.read(tourGoodsDocumentsProvider);
                    unawaited(
                      context.push<void>(
                        '/pdf-preview',
                        extra: PdfPreviewArgs(
                          title: title,
                          fileName: TourGoodsDocuments.fileName(
                            args.kind,
                            args.tourNumber,
                          ),
                          load: () => documents.build(
                            kind: args.kind,
                            tourNumber: args.tourNumber,
                            driverName: args.driverName,
                            date: args.date,
                            lines: args.lines,
                          ),
                        ),
                      ),
                    );
                  },
          ),
        ),
      ],
    );
  }
}
