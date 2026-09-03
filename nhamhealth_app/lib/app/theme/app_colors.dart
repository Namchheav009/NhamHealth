import 'package:flutter/material.dart';

import 'app_shadows.dart';

abstract class AppColors {
  AppColors._();

  static const Color primaryPink = Color(0xFFFF5364);
  static const Color primaryGreen = Color(0xFF00A651);
  static const Color navigationGreen = Color(0xFF4DBE84);
  static const Color favoriteRed = Color(0xFFFF2437);
  static const Color darkGreen = Color(0xFF075E2D);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color errorCoral = Color(0xFFFF6B6B);

  static const Color backgroundMint = Color(0xFFEFF8F2);
  static const Color backgroundCream = Color(0xFFF4F4D9);
  static const Color surface = Color(0xFFF8FAF5);
  static const Color field = Color(0xFFFAFCF9);
  static const Color border = Color(0xFFDDE9DF);
  static const Color mutedText = Color(0xFF7E9488);
  static const Color placeholder = Color(0xFFADB7B0);

  static const Color homeBackground = Color(0xFFFFFBFC);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color softPink = Color(0xFFFFF5F7);
  static const Color softPinkBorder = Color(0xFFFFD7DE);
  static const Color softGreen = Color(0xFFF1FFF2);
  static const Color primaryText = Color(0xFF414141);
  static const Color secondaryText = Color(0xFF858585);
  static const Color inactiveText = Color(0xFF929292);
  static const Color progressTrack = Color(0xFFDDE3DF);
}

/// Semantic colors that automatically adapt to the active app theme.
///
/// Prefer these tokens for surfaces and text. Brand and status colors can
/// continue to use [AppColors] directly when they should not change by theme.
extension AppColorContext on BuildContext {
  ColorScheme get appColorScheme => Theme.of(this).colorScheme;

  bool get appIsDark => Theme.of(this).brightness == Brightness.dark;

  Color get appBackground => Theme.of(this).scaffoldBackgroundColor;

  Color get appSurface => appColorScheme.surface;

  Color get appSurfaceLow =>
      appIsDark ? appColorScheme.surfaceContainerLow : AppColors.cardSurface;

  Color get appElevatedSurface =>
      appIsDark ? appColorScheme.surfaceContainerHigh : AppColors.cardSurface;

  /// A quiet surface for inputs and controls nested inside a card.
  Color get appField =>
      appIsDark ? appColorScheme.surfaceContainerHigh : AppColors.field;

  /// Surface used by search controls. It is slightly elevated from the page
  /// in dark mode without becoming a bright grey block.
  Color get appSearchSurface =>
      appIsDark ? appColorScheme.surfaceContainerHigh : AppColors.cardSurface;

  /// A slightly tinted page section. This replaces fixed near-white fills
  /// that become glaring blocks when the rest of the app is dark.
  Color get appSubtleSurface =>
      appIsDark ? appColorScheme.surfaceContainerLow : const Color(0xFFF7FAF8);

  /// Foreground used on solid brand-colored controls.
  Color get appOnBrand => appIsDark ? const Color(0xFF002C18) : Colors.white;

  Color get appMutedSurface => appColorScheme.surfaceContainerHighest;

  Color get appSelectedSurface => appColorScheme.primaryContainer;

  Color get appText => appColorScheme.onSurface;

  Color get appMutedText => appColorScheme.onSurfaceVariant;

  Color get appBorder => appColorScheme.outline;

  Color get appStrongBorder => appColorScheme.outline;

  Color get appSoftGreen =>
      appIsDark
          ? Color.alphaBlend(
            appColorScheme.primary.withValues(alpha: 0.13),
            appColorScheme.surfaceContainerLow,
          )
          : AppColors.softGreen;

  Color get appSoftPink =>
      appIsDark
          ? Color.alphaBlend(
            appColorScheme.secondary.withValues(alpha: 0.12),
            appColorScheme.surfaceContainerLow,
          )
          : AppColors.softPink;

  Color get appDangerSurface =>
      appIsDark ? const Color(0xFF402327) : const Color(0xFFFFF1F1);

  Color get appOnDangerSurface =>
      appIsDark ? const Color(0xFFFFB4BA) : const Color(0xFFB3261E);

  Color get appWarningSurface =>
      appIsDark ? const Color(0xFF332B16) : const Color(0xFFFFF7E2);

  Color get appOnWarningSurface =>
      appIsDark ? const Color(0xFFFFD875) : const Color(0xFF785A00);

  Color get appShadow =>
      Colors.black.withValues(alpha: appIsDark ? 0.38 : 0.08);

  List<BoxShadow> get appCardShadow => [
    BoxShadow(
      color: appShadow,
      blurRadius: 18,
      offset: Offset(0, appIsDark ? 7 : 6),
    ),
    if (!appIsDark)
      const BoxShadow(
        color: Color(0x66FFFFFF),
        blurRadius: 4,
        offset: Offset(-1, -2),
      ),
  ];

  List<BoxShadow> get appTileShadow => [
    BoxShadow(
      color:
          appIsDark
              ? Colors.black.withValues(alpha: 0.26)
              : const Color(0x0D263D30),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  /// Softer elevation used by cards on the home dashboard.
  List<BoxShadow> get appHomeCardShadow =>
      appIsDark
          ? appCardShadow
          : const [
            BoxShadow(
              color: Color(0x1431543F),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ];

  List<BoxShadow> get appHomeTileShadow =>
      appIsDark
          ? appTileShadow
          : const [
            BoxShadow(
              color: Color(0x1231543F),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ];

  List<BoxShadow> get appInnerShadow =>
      appIsDark
          ? const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 7,
              offset: Offset(-1, -1),
            ),
            BoxShadow(
              color: Color(0x1839D879),
              blurRadius: 3,
              offset: Offset(1, 1),
            ),
          ]
          : AppShadows.innerSurface;
}
