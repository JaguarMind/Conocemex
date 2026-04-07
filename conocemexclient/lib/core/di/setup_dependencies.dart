import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

import '/core/network/api_client.dart';
import '/core/network/dio_config.dart';
import '/core/services/biometric_service.dart';
import '/core/services/secure_storage_service.dart';
import '/features/auth/data/datasources/auth_remote_data_source.dart';
import '/features/auth/data/repositories/auth_repository_impl.dart';
import '/features/auth/domain/repositories/auth_repository.dart';
import '/features/auth/domain/usecases/login_usecase.dart';
import '/features/auth/domain/usecases/google_login_usecase.dart';
import '/features/auth/domain/usecases/biometric_login_usecase.dart';
import '/features/auth/domain/usecases/logout_usecase.dart';
import '/features/auth/presentation/viewmodels/login_viewmodel.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Services
  final secureStorageService = SecureStorageService();
  await secureStorageService.init();
  getIt.registerSingleton<SecureStorageService>(secureStorageService);
  getIt.registerSingleton<BiometricService>(BiometricService());

  // Network
  final dio = DioConfig.createDio(token: secureStorageService.getToken());
  getIt.registerSingleton<Dio>(dio);
  getIt.registerSingleton<ApiClient>(ApiClient(dio));

  // Data Sources
  getIt.registerSingleton<AuthRemoteDataSource>(
    AuthRemoteDataSourceImpl(getIt<ApiClient>()),
  );

  // Repositories
  getIt.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(
      remoteDataSource: getIt<AuthRemoteDataSource>(),
      storageService: getIt<SecureStorageService>(),
    ),
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
