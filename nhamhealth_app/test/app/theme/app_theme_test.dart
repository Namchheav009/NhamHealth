import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/app/theme/app_colors.dart';
import 'package:nhamhealth_flutter/app/theme/app_theme.dart';

void main() {
  test('light theme preserves the original NhamHealth UI colors', () {
    final theme = AppTheme.light;
    final colors = theme.colorScheme;

    expect(theme.brightness, Brightness.light);
    expect(theme.scaffoldBackgroundColor, AppColors.homeBackground);
    expect(colors.primary, AppColors.primaryGreen);
    expect(colors.secondary, AppColors.primaryPink);
    expect(colors.surface, AppColors.cardSurface);
    expect(colors.onSurface, AppColors.primaryText);
    expect(colors.onSurfaceVariant, AppColors.secondaryText);
    expect(colors.outline, AppColors.border);
    expect(theme.cardTheme.color, AppColors.cardSurface);
    expect(theme.inputDecorationTheme.fillColor, AppColors.field);
  });

  test('dark theme provides readable surfaces and component colors', () {
    final theme = AppTheme.dark;
    final colors = theme.colorScheme;

    expect(theme.brightness, Brightness.dark);
    expect(
      colors.onSurface.computeLuminance(),
      greaterThan(colors.surface.computeLuminance()),
    );
    expect(theme.cardTheme.color, colors.surface);
    expect(
      theme.inputDecorationTheme.fillColor,
      colors.surfaceContainerHighest,
    );
    expect(
      theme.filledButtonTheme.style?.backgroundColor?.resolve({}),
      colors.primary,
    );
    expect(
      theme.outlinedButtonTheme.style?.side?.resolve({})?.color,
      colors.outline,
    );
  });

  testWidgets('semantic app colors switch between light and dark', (
    tester,
  ) async {
    late Color lightSurface;
    late Color darkSurface;
    late Color darkText;
    late Color darkBorder;

    Widget sample(ThemeData theme, void Function(BuildContext) capture) {
      return MaterialApp(
        theme: theme,
        home: Builder(
          builder: (context) {
            capture(context);
            return const Scaffold(body: SizedBox());
          },
        ),
      );
    }

    await tester.pumpWidget(
      sample(AppTheme.light, (context) => lightSurface = context.appSurface),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      sample(AppTheme.dark, (context) {
        darkSurface = context.appSurface;
        darkText = context.appText;
        darkBorder = context.appBorder;
      }),
    );
    await tester.pumpAndSettle();

    expect(darkSurface, isNot(lightSurface));
    expect(
      darkText.computeLuminance(),
      greaterThan(darkSurface.computeLuminance()),
    );
    expect(darkBorder, isNot(darkSurface));
  });
}
