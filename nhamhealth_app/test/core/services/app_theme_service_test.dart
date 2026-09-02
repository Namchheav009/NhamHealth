import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/core/services/app_theme_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('loads a saved dark theme', () async {
    FlutterSecureStorage.setMockInitialValues({
      'app_theme_mode': ThemeMode.dark.name,
    });
    final service = AppThemeService();

    expect(await service.loadThemeMode(), ThemeMode.dark);
    expect(service.themeMode, ThemeMode.dark);
  });

  test('supports every theme mode and follows the system by default', () {
    expect(AppThemeService.themeModeForValue(null), ThemeMode.system);
    expect(AppThemeService.themeModeForValue('unsupported'), ThemeMode.system);
    expect(AppThemeService.themeModeForValue('system'), ThemeMode.system);
    expect(AppThemeService.themeModeForValue('light'), ThemeMode.light);
    expect(AppThemeService.themeModeForValue('dark'), ThemeMode.dark);
  });

  test('persists a selected theme', () async {
    final service = AppThemeService();
    await service.saveThemeMode(ThemeMode.dark);

    expect(await service.loadThemeMode(), ThemeMode.dark);
  });
}
