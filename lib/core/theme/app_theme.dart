import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moment/core/theme/accent_presets.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/core/theme/app_component_sizes.dart';
import 'package:moment/core/theme/app_radius.dart';
import 'package:moment/core/theme/app_typography.dart';
import 'package:moment/core/theme/moment_colors.dart';

/// Complete Moment theme. Components consume tokens — never raw Color values.
class AppTheme {
  const AppTheme._();

  static ThemeData light({Color? accent}) {
    final primary = accent ?? AppColors.accent;
    return _build(
      brightness: Brightness.light,
      background: AppColors.background,
      surface: AppColors.surface,
      elevated: AppColors.surfaceElevated,
      textTheme: AppTypography.lightTextTheme,
      divider: AppColors.border,
      primary: primary,
      onPrimary: AppColors.surface,
      error: AppColors.error,
      primarySoft: accentSoftFor(primary, isDark: false),
    );
  }

  static ThemeData dark({Color? accent}) {
    final primary = accent ?? AppColors.violet;
    return _build(
      brightness: Brightness.dark,
      background: AppColors.backgroundDark,
      surface: AppColors.surfaceDark,
      elevated: AppColors.surfaceElevatedDark,
      textTheme: AppTypography.darkTextTheme,
      divider: AppColors.borderDark,
      primary: primary,
      onPrimary: Colors.white,
      error: AppColors.errorDark,
      primarySoft: accentSoftFor(primary, isDark: true),
    );
  }

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color elevated,
    required TextTheme textTheme,
    required Color divider,
    required Color primary,
    required Color onPrimary,
    required Color error,
    required Color primarySoft,
  }) {
    final isDark = brightness == Brightness.dark;
    final onSurface = textTheme.bodyLarge!.color!;
    final momentColors = MomentColors.resolve(
      brightness: brightness,
      accent: primary,
    );
    final warm = momentColors.sendCoral;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppTypography.fontFamily,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dividerColor: divider,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      extensions: [momentColors],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primarySoft,
        onPrimaryContainer: primary,
        secondary: warm,
        onSecondary: Colors.white,
        tertiary: AppColors.champagne,
        onTertiary: AppColors.ink,
        error: error,
        onError: surface,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: elevated,
        outline: divider,
        outlineVariant: divider.withValues(alpha: 0.7),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        toolbarHeight: AppComponentSizes.toolbarHeight,
        titleSpacing: 0,
        actionsPadding: const EdgeInsets.only(right: 8),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                systemNavigationBarColor: background,
                systemNavigationBarIconBrightness: Brightness.light,
              )
            : SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                systemNavigationBarColor: background,
                systemNavigationBarIconBrightness: Brightness.dark,
              ),
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      iconTheme: IconThemeData(
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        size: AppComponentSizes.iconMd,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          iconSize: AppComponentSizes.iconMd,
          minimumSize: const Size(
            AppComponentSizes.iconButton,
            AppComponentSizes.iconButton,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          minimumSize: const Size(64, AppComponentSizes.buttonHeightLg),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          minimumSize: const Size(64, AppComponentSizes.buttonHeightLg),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: BorderSide(color: divider),
          minimumSize: const Size(64, AppComponentSizes.buttonHeightLg),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: textTheme.labelLarge,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        isDense: true,
        labelStyle: textTheme.bodyMedium,
        hintStyle: textTheme.bodyMedium,
        border: OutlineInputBorder(
          borderRadius: AppRadius.lgAll,
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.lgAll,
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.lgAll,
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xxlAll),
        showDragHandle: true,
        dragHandleColor: isDark
            ? AppColors.textTertiaryDark
            : AppColors.textTertiary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? elevated : AppColors.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.cream,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),
      listTileTheme: ListTileThemeData(
        dense: true,
        minLeadingWidth: 20,
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
        iconColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
      ),
      switchTheme: SwitchThemeData(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return isDark ? AppColors.textTertiaryDark : Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return isDark ? elevated : AppColors.border;
        }),
      ),
      radioTheme: RadioThemeData(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return isDark ? AppColors.textTertiaryDark : AppColors.textTertiary;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: elevated,
        selectedColor: primarySoft,
        labelStyle: textTheme.labelMedium!,
        side: BorderSide(color: divider),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        circularTrackColor: primarySoft,
      ),
      dividerTheme: DividerThemeData(color: divider, thickness: 0.5, space: 1),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
        iconSize: AppComponentSizes.iconLg,
        sizeConstraints: const BoxConstraints.tightFor(
          width: 48,
          height: 48,
        ),
        shape: const CircleBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: background,
        indicatorColor: primarySoft,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: selected
                ? primary
                : (isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiary),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
      ),
    );
  }
}
