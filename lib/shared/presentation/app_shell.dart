import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/feedback/haptics.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';

/// Rahmen der fünf Hauptbereiche. Die untere Navigation ist das Einzige,
/// was auf dem Bildschirm stehen bleibt.
class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  static const _paths = [
    '/home',
    '/tours',
    '/delivery-notes',
    '/invoices',
    '/more',
  ];

  /// Welcher Reiter zu einer Seite gehört. Unterseiten gehören zu ihrem Bereich;
  /// alles, was nicht Start, Touren, Lieferschein oder Rechnung ist (Produkte,
  /// Auswertungen, Belege, Fahrer, Konto …), liegt unter „Mehr“.
  static int _indexFor(String path) {
    if (path.startsWith('/home')) return 0;
    if (path.startsWith('/tours')) return 1;
    if (path.startsWith('/delivery-notes')) return 2;
    if (path.startsWith('/invoices')) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final location = GoRouterState.of(context).uri.path;
    final index = _indexFor(location);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      body: child,
      bottomNavigationBar: keyboardOpen
          ? null
          : DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: NavigationBar(
                selectedIndex: index,
                onDestinationSelected: (selected) {
                  Haptics.select();
                  context.go(_paths[selected]);
                },
                destinations: [
                  NavigationDestination(
                    icon: const Icon(AppIcons.home),
                    label: strings.home,
                  ),
                  NavigationDestination(
                    icon: const Icon(AppIcons.tour),
                    label: strings.tours,
                  ),
                  NavigationDestination(
                    icon: const Icon(AppIcons.deliveryNote),
                    label: strings.navDeliveryNote,
                  ),
                  NavigationDestination(
                    icon: const Icon(AppIcons.invoice),
                    label: strings.navInvoice,
                  ),
                  NavigationDestination(
                    icon: const Icon(AppIcons.more),
                    label: strings.more,
                  ),
                ],
              ),
            ),
    );
  }
}
