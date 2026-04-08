import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/services/biometric_service.dart';
import '/core/services/secure_storage_service.dart';
import '/features/auth/data/datasources/auth_remote_data_source.dart';
import '/features/auth/data/repositories/auth_repository_impl.dart';
import '/features/auth/domain/repositories/auth_repository.dart';
import '/features/auth/domain/usecases/biometric_login_usecase.dart';
import '/features/auth/domain/usecases/google_login_usecase.dart';
import '/features/auth/domain/usecases/login_usecase.dart';
import '/features/auth/domain/usecases/logout_usecase.dart';
import '/features/auth/presentation/viewmodels/login_viewmodel.dart';
import '/features/profile/data/datasources/profile_remote_data_source.dart';
import '/features/profile/data/repositories/profile_repository_impl.dart';
import '/features/profile/domain/repositories/profile_repository.dart';
import '/features/profile/domain/usecases/get_current_profile_usecase.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Services
  final secureStorageService = SecureStorageService();
  await secureStorageService.init();
  getIt.registerSingleton<SecureStorageService>(secureStorageService);
  getIt.registerSingleton<BiometricService>(BiometricService());

  getIt.registerSingleton<SupabaseClient>(Supabase.instance.client);

  // Data Sources
  getIt.registerSingleton<AuthRemoteDataSource>(
    AuthRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );

  // Repositories
  getIt.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(
      remoteDataSource: getIt<AuthRemoteDataSource>(),
      supabaseClient: getIt<SupabaseClient>(),
      storageService: getIt<SecureStorageService>(),
    ),
  );

  // Profile data layer
  getIt.registerSingleton<ProfileRemoteDataSource>(
    ProfileRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );
  getIt.registerSingleton<ProfileRepository>(
    ProfileRepositoryImpl(remoteDataSource: getIt<ProfileRemoteDataSource>()),
  );

  // Use Cases
  getIt.registerSingleton<LoginUsecase>(LoginUsecase(getIt<AuthRepository>()));
  getIt.registerSingleton<GoogleLoginUsecase>(
    GoogleLoginUsecase(getIt<AuthRepository>()),
  );
  getIt.registerSingleton<BiometricLoginUsecase>(
    BiometricLoginUsecase(getIt<AuthRepository>()),
  );
  getIt.registerSingleton<LogoutUsecase>(
    LogoutUsecase(getIt<AuthRepository>()),
  );
  getIt.registerSingleton<GetCurrentProfileUseCase>(
    GetCurrentProfileUseCase(getIt<ProfileRepository>()),
  );

  // ViewModels
  getIt.registerSingleton<LoginViewModel>(
    LoginViewModel(
      loginUsecase: getIt<LoginUsecase>(),
      googleLoginUsecase: getIt<GoogleLoginUsecase>(),
      biometricLoginUsecase: getIt<BiometricLoginUsecase>(),
      logoutUsecase: getIt<LogoutUsecase>(),
      biometricService: getIt<BiometricService>(),
    ),
  );
}
