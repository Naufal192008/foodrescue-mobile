import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens "Kinetic Harvest" — diambil dari stitch_food_rescue_platform_ui.
class AppColors {
  // Core
  static const primary = Color(0xFF006B2C);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF00873A);
  static const onPrimaryContainer = Color(0xFFF8FFF3);
  static const secondary = Color(0xFFA73A00);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFFD651E);
  static const onSecondaryContainer = Color(0xFF571A00);
  static const tertiary = Color(0xFF216933);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFF3D834A);
  static const onTertiaryContainer = Color(0xFFF9FFF4);

  // Semantic
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  // Surfaces
  static const background = Color(0xFFF8FAF7);
  static const onBackground = Color(0xFF191C1B);
  static const surface = Color(0xFFF8FAF7);
  static const onSurface = Color(0xFF191C1B);
  static const surfaceVariant = Color(0xFFE1E3E0);
  static const onSurfaceVariant = Color(0xFF3E4A3E);
  static const outline = Color(0xFF6E7A6D);
  static const outlineVariant = Color(0xFFBDCABB);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF2F4F1);
  static const surfaceContainer = Color(0xFFECEEEB);
  static const surfaceContainerHigh = Color(0xFFE7E9E6);
  static const surfaceContainerHighest = Color(0xFFE1E3E0);
  static const surfaceDim = Color(0xFFD8DBD8);
  static const surfaceBright = Color(0xFFF8FAF7);

  // Fixed / Inverse
  static const inverseSurface = Color(0xFF2E312F);
  static const inverseOnSurface = Color(0xFFEFF1EE);
  static const inversePrimary = Color(0xFF6FDD84);
  static const surfaceTint = Color(0xFF006E2E);
  static const primaryFixed = Color(0xFF8BFA9E);
  static const primaryFixedDim = Color(0xFF6FDD84);
  static const onPrimaryFixed = Color(0xFF002109);
  static const onPrimaryFixedVariant = Color(0xFF005321);
  static const secondaryFixed = Color(0xFFFFDBCE);
  static const secondaryFixedDim = Color(0xFFFFB599);
  static const onSecondaryFixed = Color(0xFF370E00);
  static const onSecondaryFixedVariant = Color(0xFF802A00);
  static const tertiaryFixed = Color(0xFFA9F4AF);
  static const tertiaryFixedDim = Color(0xFF8ED795);
  static const onTertiaryFixed = Color(0xFF002108);
  static const onTertiaryFixedVariant = Color(0xFF005320);

  // Struktural hairline dari DESIGN.md
  static const hairline = Color(0xFFE2EFE7);
}

class AppTheme {
  static const radiusCard = 24.0; // rounded-3xl bento cards
  static const radiusInput = 14.0; // rounded-xl inputs
  static const radiusChip = 999.0; // pill

  static ColorScheme get _scheme => const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        background: AppColors.background,
        onBackground: AppColors.onBackground,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        surfaceVariant: AppColors.surfaceVariant,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: AppColors.inverseSurface,
        onInverseSurface: AppColors.inverseOnSurface,
        inversePrimary: AppColors.inversePrimary,
        surfaceTint: AppColors.surfaceTint,
      );

  /// label-caps: Space Grotesk 10px, w700, tracking 0.08em, uppercase
  static TextStyle labelCaps({Color color = AppColors.onSurfaceVariant}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        height: 12 / 10,
        color: color,
      );

  /// label-md: Space Grotesk 12px, w600, tracking 0.04em
  static TextStyle labelMd({Color color = AppColors.onSurface}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.48,
        height: 16 / 12,
        color: color,
      );

  /// headline-sm: Space Grotesk 20px w600
  static TextStyle headlineSm({Color color = AppColors.onSurface}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 26 / 20,
        color: color,
      );

  /// headline-md: Space Grotesk 24px w600
  static TextStyle headlineMd({Color color = AppColors.onSurface}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 30 / 24,
        color: color,
      );

  /// headline-lg: Space Grotesk 32px w700
  static TextStyle headlineLg({Color color = AppColors.onSurface}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 38 / 32,
        letterSpacing: -0.5,
        color: color,
      );

  /// numeric-metric-lg: Space Grotesk 44px w700 tabular
  static TextStyle metricLg({Color color = AppColors.onSurface}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 44,
        fontWeight: FontWeight.w700,
        height: 48 / 44,
        letterSpacing: -0.8,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: color,
      );

  /// numeric-metric-sm: Space Grotesk 24px w700 tabular
  static TextStyle metricSm({Color color = AppColors.onSurface}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 28 / 24,
        letterSpacing: -0.5,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: color,
      );

  /// body-md: Inter 14px
  static TextStyle bodyMd({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(fontSize: 14, height: 20 / 14, color: color);

  /// body-sm: Inter 12px
  static TextStyle bodySm({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 16 / 12,
        letterSpacing: 0.1,
        color: color,
      );

  /// body-lg: Inter 16px
  static TextStyle bodyLg({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 16,
        height: 24 / 16,
        letterSpacing: -0.16,
        color: color,
      );

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: _scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: GoogleFonts.inter().fontFamily,
    );

    final textTheme = base.textTheme.copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(fontSize: 56, fontWeight: FontWeight.w700, letterSpacing: -2.2, height: 60 / 56, color: AppColors.onSurface),
      headlineLarge: AppTheme.headlineLg(),
      headlineMedium: AppTheme.headlineMd(),
      headlineSmall: AppTheme.headlineSm(),
      bodyLarge: AppTheme.bodyLg(),
      bodyMedium: AppTheme.bodyMd(),
      bodySmall: AppTheme.bodySm(),
      labelLarge: AppTheme.labelMd(),
      labelMedium: AppTheme.labelMd(),
      labelSmall: AppTheme.labelCaps(),
      titleLarge: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.onSurface),
      titleMedium: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onSurface),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          elevation: 0,
          textStyle: AppTheme.labelMd(color: AppColors.onPrimary),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          textStyle: AppTheme.labelMd(color: AppColors.onPrimary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTheme.labelMd(color: AppColors.primary),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurface,
          side: const BorderSide(color: AppColors.outlineVariant),
          minimumSize: const Size.fromHeight(48),
          shape: const StadiumBorder(),
          textStyle: AppTheme.labelMd(color: AppColors.onSurface),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: AppTheme.bodyMd(
          color: AppColors.outline.withOpacity(0.5),
        ),
        labelStyle: AppTheme.bodyMd(color: AppColors.onSurface),
        prefixIconColor: AppColors.outline,
        suffixIconColor: AppColors.outline,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          borderSide: const BorderSide(color: AppColors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          borderSide: const BorderSide(color: AppColors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: AppColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppTheme.radiusCard)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.inverseSurface,
        contentTextStyle: TextStyle(color: AppColors.inverseOnSurface),
        shape: StadiumBorder(),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryContainer,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }
}