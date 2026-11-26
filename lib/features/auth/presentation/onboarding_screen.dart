import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/preferences/app_preferences.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/buttons/primary_button.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';

/// Einführung in drei Schritten: je eine Überschrift und ein Satz.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _page = 0;

  Future<void> _finish() async {
    await ref.read(appPreferencesProvider).markOnboardingDone();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final pages = [
      (
        strings.onboardingStockTitle,
        strings.onboardingStockText,
        AppIcons.stock,
      ),
      (
        strings.onboardingToursTitle,
        strings.onboardingToursText,
        AppIcons.tour,
      ),
      (
        strings.onboardingDocumentsTitle,
        strings.onboardingDocumentsText,
        AppIcons.invoice,
      ),
    ];
    final last = _page == pages.length - 1;
    final (title, text, icon) = pages[_page];
    return AppScreen(
      title: title,
      showBack: false,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Icon(icon, size: 40),
              const SizedBox(height: AppSpacing.md),
              Text(text, style: AppText.body),
              const SizedBox(height: AppSpacing.md),
              Text(
                strings.onboardingPage(_page + 1, pages.length),
                style: AppText.label,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: last ? strings.onboardingStart : strings.onboardingNext,
          onPressed: () => last ? _finish() : setState(() => _page += 1),
        ),
        if (!last)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: _finish,
              child: Text(strings.onboardingSkip),
            ),
          ),
      ],
    );
  }
}
