import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/layout/sticky_action.dart';

/// Hauptseiten ohne Zurück-Pfeil: die fünf Reiter (Start, Touren, Lieferschein,
/// Rechnung, Mehr), Anmeldung und Einführung.
const _rootPaths = {
  '/home',
  '/tours',
  '/delivery-notes',
  '/invoices',
  '/more',
  '/login',
  '/onboarding',
};

/// Die übergeordnete Seite, wenn es keinen Verlauf zum Zurückgehen gibt.
String _parentPath(String path) {
  const underMore = {
    '/products',
    '/reports',
    '/expenses',
    '/drivers',
    '/users',
    '/company',
    '/account',
    '/help',
    '/platform',
  };
  if (path == '/forgot-password') return '/login';
  if (path == '/tour-goods') return '/tours';
  if (underMore.contains(path)) return '/more';
  final cut = path.lastIndexOf('/');
  if (cut <= 0) return '/home';
  return path.substring(0, cut);
}

/// Grundgerüst jedes Screens. Alles scrollt: Kopf (Zurück, Titel, Aktionen)
/// wandert mit dem Inhalt weg, nichts klebt. Nur die untere Navigation der
/// Shell bleibt stehen. Die Statusleiste hat weißen Grund, damit Inhalt nicht
/// unter Uhrzeit und Akku durchscheint.
class AppScreen extends StatelessWidget {
  /// Screen aus einer Liste von Widgets (Formulare, Detailansichten).
  AppScreen({
    required this.title,
    required List<Widget> children,
    this.actions = const [],
    this.onRefresh,
    this.controller,
    this.showBack,
    this.onBackPressed,
    super.key,
  }) : slivers = [
         SliverPadding(
           padding: const EdgeInsetsDirectional.fromSTEB(
             AppSpacing.page,
             0,
             AppSpacing.page,
             AppSpacing.xl,
           ),
           sliver: SliverList.list(children: children),
         ),
       ];

  /// Screen aus Slivers (lange Listen mit Nachladen).
  const AppScreen.slivers({
    required this.title,
    required this.slivers,
    this.actions = const [],
    this.onRefresh,
    this.controller,
    this.showBack,
    this.onBackPressed,
    super.key,
  });

  /// Seitentitel (Größe 26).
  final String title;

  /// Inhalt.
  final List<Widget> slivers;

  /// Aktionen rechts im Kopf (z. B. „+“); sie scrollen mit.
  final List<Widget> actions;

  /// Zum Herunterziehen und Neuladen.
  final Future<void> Function()? onRefresh;

  /// Eigener Scroll-Controller, z. B. zum Nachladen.
  final ScrollController? controller;

  /// Eigene Zurück-Aktion (z. B. wenn es keine Seite zurück gibt); zeigt den
  /// Pfeil immer.
  final VoidCallback? onBackPressed;

  /// Zurück-Pfeil; ohne Angabe nur, wenn es eine Seite zurück gibt.
  final bool? showBack;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    final path = router?.routeInformationProvider.value.uri.path;
    // Jede Unterseite hat einen Zurück-Pfeil, auch wenn sie ohne Verlauf geöffnet
    // wurde (dann geht es zur übergeordneten Seite). Nur die Hauptseiten der fünf
    // Reiter und Anmeldung/Einführung haben keinen.
    final isSubPage = path != null && !_rootPaths.contains(path);
    final canGoBack =
        onBackPressed != null ||
        (showBack ?? (Navigator.of(context).canPop() || isSubPage));
    final effectiveBack =
        onBackPressed ??
        (path == null || router == null
            ? null
            : () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  router.go(_parentPath(path));
                }
              });
    final topInset = MediaQuery.paddingOf(context).top;
    Widget scroll = CustomScrollView(
      controller: controller,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _Header(
            title: title,
            showBack: canGoBack,
            onBack: effectiveBack,
            actions: actions,
          ),
        ),
        ...slivers,
      ],
    );
    if (onRefresh != null) {
      scroll = RefreshIndicator(onRefresh: onRefresh!, child: scroll);
    }
    return _ScreenFrame(topInset: topInset, scroll: scroll);
  }
}

class _ScreenFrame extends StatefulWidget {
  const _ScreenFrame({required this.topInset, required this.scroll});

  final double topInset;
  final Widget scroll;

  @override
  State<_ScreenFrame> createState() => _ScreenFrameState();
}

class _ScreenFrameState extends State<_ScreenFrame> {
  final ValueNotifier<Widget?> _slot = ValueNotifier(null);

  // Kein dispose: StickyAction leert den Platz erst im nächsten Frame, dann ist
  // der Screen schon weg. Ein freigegebener Notifier würde dort Fehler werfen.

  @override
  Widget build(BuildContext context) {
    final topInset = widget.topInset;
    final scroll = widget.scroll;
    return StickyActionScope(
      slot: _slot,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppTheme.statusBar,
        child: Scaffold(
          backgroundColor: AppColors.paper,
          body: Column(
            children: [
              ColoredBox(
                color: AppColors.paper,
                child: SizedBox(height: topInset, width: double.infinity),
              ),
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: scroll,
                ),
              ),
              StickyActionBar(slot: _slot),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.showBack,
    required this.onBack,
    required this.actions,
  });

  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.xs,
        AppSpacing.xxs,
        AppSpacing.xs,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBack || actions.isNotEmpty)
            Row(
              children: [
                if (showBack)
                  IconButton(
                    tooltip: strings.back,
                    onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                    icon: Icon(AppIcons.back(context)),
                  ),
                const Spacer(),
                ...actions,
              ],
            )
          else
            const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.xs,
            ),
            child: Text(title, style: AppText.pageTitle),
          ),
        ],
      ),
    );
  }
}
