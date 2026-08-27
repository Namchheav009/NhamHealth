import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/routes/app_pages.dart';
import 'app/bindings/initial_binding.dart';
import 'app/theme/app_colors.dart';
import 'app/translations/app_translations.dart';
import 'core/services/app_locale_service.dart';
import 'core/services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (PushNotificationService.isSupported) {
    await Firebase.initializeApp();
  }
  final localeService = AppLocaleService();
  final initialLocale = await localeService.loadLocale();
  InitialBinding.ensureRegistered(localeService: localeService);
  if (PushNotificationService.isSupported) {
    await PushNotificationService(authService: Get.find()).initialize();
  }

  runApp(NhamHealthApp(initialLocale: initialLocale));
}

class NhamHealthApp extends StatelessWidget {
  const NhamHealthApp({
    super.key,
    this.initialLocale = AppLocaleService.fallbackLocale,
  });

  final Locale initialLocale;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Nham Health',
      debugShowCheckedModeBanner: false,
      translations: AppTranslations(),
      locale: initialLocale,
      fallbackLocale: AppLocaleService.fallbackLocale,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.homeBackground,
        fontFamilyFallback: const ['Arial', 'sans-serif'],
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          primary: AppColors.primaryGreen,
          secondary: AppColors.primaryPink,
          surface: AppColors.cardSurface,
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: AppColors.primaryText,
          displayColor: AppColors.primaryText,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primaryText,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardSurface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.field,
          hintStyle: const TextStyle(color: AppColors.placeholder),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.primaryGreen,
              width: 1.5,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.darkGreen,
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primaryGreen,
        ),
      ),
      initialRoute: AppPages.initialRoute,
      getPages: AppPages.pages,
      initialBinding: InitialBinding(),
    );
  }
}

//===================================API CONNECTION TESTING CODE===================================

// void main() {
//   runApp(const NhamHealthApp());
// }

// class NhamHealthApp extends StatelessWidget {
//   const NhamHealthApp({super.key, this.api});

//   final HealthApi? api;

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'NhamHealth',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: const Color(0xFF147D64),
//         ),
//         useMaterial3: true,
//       ),
//       home: ApiConnectionPage(api: api ?? ApiService()),
//     );
//   }
// }

// class ApiConnectionPage extends StatefulWidget {
//   const ApiConnectionPage({super.key, required this.api});

//   final HealthApi api;

//   @override
//   State<ApiConnectionPage> createState() => _ApiConnectionPageState();
// }

// class _ApiConnectionPageState extends State<ApiConnectionPage> {
//   ApiHealth? _health;
//   Object? _error;
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadHealth();
//   }

//   Future<void> _loadHealth() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });

//     try {
//       final health = await widget.api.getHealth();
//       if (!mounted) return;
//       setState(() => _health = health);
//     } catch (error) {
//       if (!mounted) return;
//       setState(() {
//         _health = null;
//         _error = error;
//       });
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('NhamHealth')),
//       body: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24),
//           child: ConstrainedBox(
//             constraints: const BoxConstraints(maxWidth: 520),
//             child: Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(24),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(
//                       _error == null ? Icons.cloud_done : Icons.cloud_off,
//                       size: 56,
//                       color: _error == null
//                           ? Theme.of(context).colorScheme.primary
//                           : Theme.of(context).colorScheme.error,
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       _isLoading
//                           ? 'Connecting to Spring API…'
//                           : _error == null
//                               ? 'Connected to Spring API'
//                               : 'Could not reach Spring API',
//                       style: Theme.of(context).textTheme.headlineSmall,
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 12),
//                     if (_isLoading)
//                       const CircularProgressIndicator()
//                     else if (_health case final health?)
//                       _ConnectionDetails(
//                         health: health,
//                         baseUrl: widget.api.baseUrl,
//                       )
//                     else
//                       _ConnectionError(
//                         error: _error,
//                         baseUrl: widget.api.baseUrl,
//                       ),
//                     const SizedBox(height: 20),
//                     FilledButton.icon(
//                       onPressed: _isLoading ? null : _loadHealth,
//                       icon: const Icon(Icons.refresh),
//                       label: const Text('Test again'),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _ConnectionDetails extends StatelessWidget {
//   const _ConnectionDetails({required this.health, required this.baseUrl});

//   final ApiHealth health;
//   final String baseUrl;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Text('Status: ${health.status}'),
//         Text('Service: ${health.service}'),
//         const SizedBox(height: 8),
//         SelectableText(baseUrl, textAlign: TextAlign.center),
//       ],
//     );
//   }
// }

// class _ConnectionError extends StatelessWidget {
//   const _ConnectionError({required this.error, required this.baseUrl});

//   final Object? error;
//   final String baseUrl;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Text(
//           error.toString(),
//           textAlign: TextAlign.center,
//           style: TextStyle(color: Theme.of(context).colorScheme.error),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           'Start Spring Boot and check this URL:',
//           style: Theme.of(context).textTheme.bodySmall,
//         ),
//         SelectableText(baseUrl, textAlign: TextAlign.center),
//       ],
//     );
//   }
// }
