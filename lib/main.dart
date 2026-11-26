import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warenbestand/core/config/app_config.dart';
import 'package:warenbestand/core/preferences/app_preferences.dart';
import 'package:warenbestand/core/preferences/locale_provider.dart';
import 'package:warenbestand/core/router/app_router.dart';
import 'package:warenbestand/core/supabase/providers.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/l10n/locale_resolver.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';
import 'package:warenbestand/shared/widgets/display/offline_bar.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';
import 'package:warenbestand/shared/widgets/layout/centered_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await initializeDateFormatting('de_DE');
  await initializeDateFormatting('ar');
  final config = AppConfig.fromEnvironment();
  if (!config.isValid) {
    runApp(const _ConfigurationErrorApp());
    return;
  }
  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.supabaseAnonKey,
  );
  final prefs = AppPreferences(await SharedPreferences.getInstance());
  runApp(
    ProviderScope(
      overrides: [appPreferencesProvider.overrideWithValue(prefs)],
      child: const WarenbestandBootstrap(),
    ),
  );
}

class WarenbestandBootstrap extends ConsumerStatefulWidget {
  const WarenbestandBootstrap({super.key});

  @override
  ConsumerState<WarenbestandBootstrap> createState() =>
      _WarenbestandBootstrapState();
}

class _WarenbestandBootstrapState extends ConsumerState<WarenbestandBootstrap> {
  late final GoRouter router = createRouter(
    ref.read(sessionControllerProvider),
    showOnboarding: !ref.read(appPreferencesProvider).onboardingDone,
  );

  @override
  void initState() {
    super.initState();
    unawaited(ref.read(sessionControllerProvider).refresh());
  }

  @override
  void dispose() {
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Warenbestand',
    theme: AppTheme.light,
    debugShowCheckedModeBanner: false,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: appLocalizationsDelegates,
    locale: ref.watch(localeProvider),
    localeResolutionCallback: resolveLocale,
    routerConfig: router,
    builder: (context, child) => Column(
      children: [
        const OfflineBar(),
        Expanded(
          child: CenteredAppBody(child: child ?? const SizedBox.shrink()),
        ),
      ],
    ),
  );
}

class _ConfigurationErrorApp extends StatelessWidget {
  const _ConfigurationErrorApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: AppTheme.light,
    debugShowCheckedModeBanner: false,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: appLocalizationsDelegates,
    localeResolutionCallback: resolveLocale,
    home: Builder(
      builder: (context) => AppScreen(
        title: AppLocalizations.of(context).appTitle,
        showBack: false,
        children: [
          NoticeBanner(
            message: AppLocalizations.of(context).configurationMissing,
            kind: NoticeKind.error,
          ),
        ],
      ),
    ),
  );
}
