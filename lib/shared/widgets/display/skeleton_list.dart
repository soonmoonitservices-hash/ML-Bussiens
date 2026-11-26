import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/theme/app_theme.dart';

/// Ladeanzeige: graue Balken in der Form einer Listenzeile statt Spinner,
/// mit leichtem Schimmer (Zyklus 1,2 s). Bei „Bewegung reduzieren“ stehen
/// die Balken still.
class SkeletonList extends StatefulWidget {
  const SkeletonList({this.rows = 5, super.key});

  final int rows;

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: FadeTransition(
      opacity: Tween<double>(
        begin: 1,
        end: 0.55,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Column(
        children: [
          for (var i = 0; i < widget.rows; i++)
            const Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Bar(widthFactor: 0.6, height: 14),
                        SizedBox(height: AppSpacing.xs),
                        _Bar(widthFactor: 0.35, height: 10),
                      ],
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  SizedBox(width: 56, child: _Bar(widthFactor: 1, height: 14)),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class _Bar extends StatelessWidget {
  const _Bar({required this.widthFactor, required this.height});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    widthFactor: widthFactor,
    alignment: AlignmentDirectional.centerStart,
    child: Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.line,
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );
}
