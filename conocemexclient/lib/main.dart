import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/constants/app_constants.dart';
import 'core/di/setup_dependencies.dart';
import 'core/routes/app_routes.dart';
import 'features/auth/presentation/viewmodels/login_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  Env.validate();
  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);
  await setupDependencies();
  runApp(const ConocemexApp());
}

class ConocemexApp extends StatelessWidget {
  const ConocemexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LoginViewModel>.value(
      value: getIt<LoginViewModel>(),
      child: MaterialApp(
        title: 'Conocemex',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        initialRoute: AppConstants.splashRoute,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
