import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/theme/app_theme.dart';

/// Art eines Hinweises.
enum NoticeKind { success, error, warning }

/// Hinweis mit Statusfarbe (Text und Icon) auf heller Fläche. Ein Satz.
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({required this.message, required this.kind, super.key});

  final String message;
  final NoticeKind kind;

  @override
  Widget build(BuildContext context) {
    final (color, surface, icon) = switch (kind) {
      NoticeKind.success => (
        AppColors.success,
        AppColors.successSurface,
        AppIcons.success,
      ),
      NoticeKind.error => (
        AppColors.error,
        AppColors.errorSurface,
        AppIcons.error,
      ),
      NoticeKind.warning => (
        AppColors.warning,
        AppColors.warningSurface,
        AppIcons.warning,
      ),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppIcons.size, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message, style: AppText.body.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}
