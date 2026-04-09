import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/constants/app_constants.dart';
import 'core/di/setup_dependencies.dart';
import 'core/routes/app_routes.dart';
import 'core/services/locale_service.dart';
import 'features/auth/presentation/viewmodels/login_viewmodel.dart';
import 'features/business/presentation/viewmodels/dashboard_viewmodel.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  Env.validate();
  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);
  await setupDependencies();

  // Cargar idioma guardado antes de renderizar
  await getIt<LocaleService>().loadSavedLocale();

  runApp(const ConocemexApp());
}

class ConocemexApp extends StatelessWidget {
  const ConocemexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LoginViewModel>.value(
          value: getIt<LoginViewModel>(),
        ),
        ChangeNotifierProvider<DashboardViewModel>.value(
          value: getIt<DashboardViewModel>(),
        ),
        ChangeNotifierProvider<LocaleService>.value(
          value: getIt<LocaleService>(),
        ),
      ],
      child: Consumer<LocaleService>(
        builder: (context, localeService, _) {
          return MaterialApp(
            title: 'Conocemex',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            ),
            locale: localeService.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            initialRoute: AppConstants.splashRoute,
            onGenerateRoute: AppRoutes.generateRoute,
          );
        },
      ),
    );
  }
}
