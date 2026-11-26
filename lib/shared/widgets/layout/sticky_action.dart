import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/theme/app_theme.dart';

/// Hält den Hauptbutton eines Screens unten fest (über Tastatur und Safe
/// Area, mit weißem Auslauf darüber). Der Button wird dort eingesetzt, wo er
/// im Inhalt steht; angezeigt wird er in der festen Leiste des AppScreen.
class StickyAction extends StatefulWidget {
  const StickyAction({required this.child, this.summary, super.key});

  final Widget child;

  /// Summe oder Ergebnis, das über dem Button mitklebt (z. B. Soll-Bargeld
  /// und Differenz), damit man es beim Eingeben immer sieht.
  final Widget? summary;

  @override
  State<StickyAction> createState() => _StickyActionState();
}

class _StickyActionState extends State<StickyAction>
    with AutomaticKeepAliveClientMixin {
  ValueNotifier<Widget?>? _slot;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _slot = StickyActionScope.maybeOf(context);
  }

  void _publish() {
    final slot = _slot;
    if (slot == null) return;
    final summary = widget.summary;
    final child = summary == null
        ? widget.child
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              summary,
              const SizedBox(height: AppSpacing.xs),
              widget.child,
            ],
          );
    _published = child;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) slot.value = child;
    });
  }

  @override
  void dispose() {
    final slot = _slot;
    if (slot != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Nur leeren, wenn kein anderer Button inzwischen übernommen hat.
        if (_ownsSlot) slot.value = null;
      });
    }
    super.dispose();
  }

  Widget? _published;

  // In langen Listen bleibt der Button am Leben, auch wenn er aus dem sichtbaren
  // Bereich scrollt (sonst verschwindet die feste Leiste beim Scrollen).
  @override
  bool get wantKeepAlive => true;

  bool get _ownsSlot => _slot?.value == _published;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_slot == null) return widget.child; // ohne AppScreen: normal anzeigen
    _publish();
    return const SizedBox.shrink();
  }
}

/// Stellt den Platz für den festen Button bereit (vom AppScreen gesetzt).
class StickyActionScope extends InheritedWidget {
  const StickyActionScope({
    required this.slot,
    required super.child,
    super.key,
  });

  final ValueNotifier<Widget?> slot;

  static ValueNotifier<Widget?>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StickyActionScope>()?.slot;

  @override
  bool updateShouldNotify(StickyActionScope oldWidget) =>
      slot != oldWidget.slot;
}

/// Die feste Leiste unten: weißer Auslauf, Button, Abstand zur Safe Area.
class StickyActionBar extends StatelessWidget {
  const StickyActionBar({required this.slot, super.key});

  final ValueNotifier<Widget?> slot;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Widget?>(
    valueListenable: slot,
    builder: (context, action, _) {
      if (action == null) return const SizedBox.shrink();
      final bottomInset = MediaQuery.viewInsetsOf(context).bottom > 0
          ? 0.0
          : MediaQuery.paddingOf(context).bottom;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            top: -AppSpacing.lg,
            left: 0,
            right: 0,
            height: AppSpacing.lg,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00FFFFFF), AppColors.paper],
                  ),
                ),
              ),
            ),
          ),
          ColoredBox(
            color: AppColors.paper,
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                AppSpacing.page,
                AppSpacing.xs,
                AppSpacing.page,
                AppSpacing.xs + bottomInset,
              ),
              child: action,
            ),
          ),
        ],
      );
    },
  );
}
