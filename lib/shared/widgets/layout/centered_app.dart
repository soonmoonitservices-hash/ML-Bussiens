import 'package:material_ui/material_ui.dart';

class CenteredAppBody extends StatelessWidget {
  const CenteredAppBody({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );
}
