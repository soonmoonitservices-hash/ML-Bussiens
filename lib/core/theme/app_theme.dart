import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/theme/app_colors.dart';
import 'package:warenbestand/core/theme/app_text.dart';

export 'package:warenbestand/core/theme/app_colors.dart';
export 'package:warenbestand/core/theme/app_icons.dart';
export 'package:warenbestand/core/theme/app_text.dart';

/// Abstände: 4 / 8 / 12 / 16 / 24 / 32.
abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  /// Seitenrand.
  static const page = 20.0;
}

/// Eckenradien: Buttons und Felder 12, Karten 14, Chips Pille.
abstract final class AppRadius {
  static const control = 12.0;
  static const surface = 14.0;
  static const pill = 999.0;
}

/// Kleinste Tippfläche.
const double kMinTapTarget = 48;

/// Das eine Theme der App. Material 3 dient nur als technische Grundlage.
abstract final class AppTheme {
  /// Statusleiste: weißer Grund, dunkle Symbole.
  static const statusBar = SystemUiOverlayStyle(
    statusBarColor: AppColors.paper,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.paper,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  static const _controlShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.control)),
  );

  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.ink,
      onPrimary: AppColors.paper,
      secondary: AppColors.ink,
      onSecondary: AppColors.paper,
      error: AppColors.error,
      onError: AppColors.paper,
      surface: AppColors.paper,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.inkMuted,
      outline: AppColors.line,
      outlineVariant: AppColors.line,
      surfaceTint: Colors.transparent,
      surfaceContainerHighest: AppColors.paperMuted,
    );
    final text = TextTheme(
      headlineMedium: AppText.pageTitle,
      titleMedium: AppText.section,
      bodyLarge: AppText.body,
      bodyMedium: AppText.body,
      bodySmall: AppText.label,
      labelLarge: AppText.bodyStrong,
      labelMedium: AppText.label,
      labelSmall: AppText.label,
      displaySmall: AppText.amountLarge,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppText.family,
      fontFamilyFallback: const [AppText.arabicFamily],
      textTheme: text,
      scaffoldBackgroundColor: AppColors.paper,
      canvasColor: AppColors.paper,
      splashFactory: NoSplash.splashFactory,
      highlightColor: AppColors.paperMuted,
      hoverColor: AppColors.paperMuted,
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.ink, size: 22),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.paper,
          disabledBackgroundColor: const Color(0xFFD4D4D4),
          disabledForegroundColor: AppColors.paper,
          minimumSize: const Size.fromHeight(52),
          shape: _controlShape,
          textStyle: AppText.body.copyWith(fontWeight: FontWeight.w600),
          elevation: 0,
          overlayColor: const Color(0x1FFFFFFF),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          disabledForegroundColor: AppColors.inkFaint,
          minimumSize: const Size.fromHeight(52),
          shape: _controlShape,
          side: const BorderSide(color: AppColors.ink),
          textStyle: AppText.body.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(kMinTapTarget, kMinTapTarget),
          shape: _controlShape,
          textStyle: AppText.body.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(kMinTapTarget, kMinTapTarget),
          iconSize: 22,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paperMuted,
        labelStyle: AppText.label,
        floatingLabelStyle: AppText.label,
        hintStyle: AppText.body.copyWith(color: AppColors.inkFaint),
        errorStyle: AppText.label.copyWith(color: AppColors.error),
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: _inputBorder(Colors.transparent),
        enabledBorder: _inputBorder(Colors.transparent),
        focusedBorder: _inputBorder(AppColors.ink, width: 1.5),
        errorBorder: _inputBorder(AppColors.error),
        focusedErrorBorder: _inputBorder(AppColors.error, width: 1.5),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        elevation: 0,
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        indicatorColor: AppColors.paperMuted,
        indicatorShape: _controlShape,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? AppColors.ink
                : AppColors.inkMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppText.label.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.ink
                : AppColors.inkMuted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.surface)),
          side: BorderSide(color: AppColors.line),
        ),
        titleTextStyle: AppText.section,
        contentTextStyle: AppText.body,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: AppText.body.copyWith(color: AppColors.paper),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: _controlShape,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.ink,
        linearTrackColor: AppColors.line,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.paper
              : AppColors.inkMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.ink
              : AppColors.paperMuted,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(AppColors.line),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.ink
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(AppColors.paper),
        side: const BorderSide(color: AppColors.inkMuted, width: 1.5),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.ink,
        selectionColor: AppColors.line,
        selectionHandleColor: AppColors.ink,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(AppRadius.control),
        ),
        borderSide: BorderSide(color: color, width: width),
      );
}
