import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/supabase/providers.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/features/tours/domain/tour.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/display/app_card.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';

/// Startseite: Begrüßung, „Heute unterwegs“ als einzige dunkle Fläche,
/// vier Bereiche.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Tour> _active = const [];
  bool _companyIncomplete = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final tours = await ref
        .read(toursRepositoryProvider)
        .list(page: 0, status: TourStatus.active);
    final company = await ref.read(companyRepositoryProvider).load();
    if (!mounted) return;
    setState(() {
      if (tours case Success(:final value)) _active = value;
      if (company case Success(:final value)) {
        _companyIncomplete =
            value.name.trim().isEmpty ||
            value.address.trim().isEmpty ||
            (value.taxNumber.trim().isEmpty && value.vatId.trim().isEmpty);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final session = ref.watch(sessionControllerProvider);
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final tiles = [
      (strings.tours, strings.tileToursSub, AppIcons.tour, '/tours'),
      (strings.products, strings.tileProductsSub, AppIcons.stock, '/products'),
      (
        strings.expenses,
        strings.tileExpensesSub,
        AppIcons.expense,
        '/expenses',
      ),
      (
        strings.deliveryNotes,
        strings.tileDeliverySub,
        AppIcons.deliveryNote,
        '/delivery-notes',
      ),
    ];
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final name = (session.profile?.name ?? '').split(' ').first;
        return AppScreen(
          title: _greeting(strings, now.hour, name),
          onRefresh: _load,
          children: [
            Text(
              DateFormat.yMMMMEEEEd(locale).format(now),
              style: AppText.label,
            ),
            const SizedBox(height: AppSpacing.md),
            if (_companyIncomplete) ...[
              NoticeBanner(
                message: strings.companyIncomplete,
                kind: NoticeKind.warning,
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () async {
                    await context.push<void>('/company');
                    if (mounted) await _load();
                  },
                  child: Text(strings.fillCompany),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            _onRoad(strings),
            const SizedBox(height: AppSpacing.md),
            for (final tile in tiles) ...[
              AppCard(
                onTap: () => tile.$4 == '/tours' || tile.$4 == '/delivery-notes'
                    ? context.go(tile.$4)
                    : unawaited(context.push<void>(tile.$4)),
                child: Row(
                  children: [
                    Icon(tile.$3, size: 28),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tile.$1, style: AppText.bodyStrong),
                          Text(tile.$2, style: AppText.label),
                        ],
                      ),
                    ),
                    Icon(AppIcons.forward(context), size: AppIcons.size),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
          ],
        );
      },
    );
  }

  Widget _onRoad(AppLocalizations strings) {
    const onInk = TextStyle(color: AppColors.paper);
    return AppCard(
      dark: true,
      onTap: () => context.go('/tours'),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.onRoadToday,
              style: AppText.label.merge(
                const TextStyle(color: AppColors.line),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (_active.isEmpty)
              Text(strings.noTourOnRoad, style: AppText.section.merge(onInk))
            else ...[
              Text(
                '${_active.length}',
                style: AppText.amountLarge.merge(onInk),
              ),
              for (final tour in _active.take(3))
                Text(tour.driverName, style: AppText.body.merge(onInk)),
            ],
          ],
        ),
      ),
    );
  }

  String _greeting(AppLocalizations strings, int hour, String name) {
    if (hour < 11) return strings.greetingMorning(name);
    if (hour < 18) return strings.greetingDay(name);
    return strings.greetingEvening(name);
  }
}
