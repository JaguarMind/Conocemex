import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/config/env.dart';
import '/core/services/biometric_service.dart';
import '/core/services/cloudinary_service.dart';
import '/core/services/gemini_service.dart';
import '/core/services/image_picker_service.dart';
import '/core/services/secure_storage_service.dart';
import '/features/auth/data/datasources/auth_remote_data_source.dart';
import '/features/auth/data/repositories/auth_repository_impl.dart';
import '/features/auth/domain/repositories/auth_repository.dart';
import '/features/auth/domain/usecases/biometric_login_usecase.dart';
import '/features/auth/domain/usecases/google_login_usecase.dart';
import '/features/auth/domain/usecases/login_usecase.dart';
import '/features/auth/domain/usecases/logout_usecase.dart';
import '/features/auth/domain/usecases/signup_usecase.dart';
import '/features/auth/presentation/viewmodels/login_viewmodel.dart';
import '/features/business/data/datasources/business_remote_data_source.dart';
import '/features/business/data/repositories/business_repository_impl.dart';
import '/features/business/domain/repositories/business_repository.dart';
import '/features/business/domain/usecases/create_business_usecase.dart';
import '/features/business/domain/usecases/get_my_businesses_usecase.dart';
import '/features/business/presentation/viewmodels/create_business_viewmodel.dart';
import '/features/business/presentation/viewmodels/dashboard_viewmodel.dart';
import '/features/category/data/datasources/category_remote_data_source.dart';
import '/features/category/data/repositories/category_repository_impl.dart';
import '/features/category/domain/repositories/category_repository.dart';
import '/features/category/domain/usecases/get_categories_usecase.dart';
import '/features/offering/data/datasources/offering_remote_data_source.dart';
import '/features/offering/data/repositories/offering_repository_impl.dart';
import '/features/offering/domain/repositories/offering_repository.dart';
import '/features/offering/domain/usecases/create_offering_usecase.dart';
import '/features/offering/domain/usecases/get_offerings_usecase.dart';
import '/features/offering/presentation/viewmodels/offerings_viewmodel.dart';
import '/features/profile/data/datasources/profile_remote_data_source.dart';
import '/features/profile/data/repositories/profile_repository_impl.dart';
import '/features/profile/domain/repositories/profile_repository.dart';
import '/features/profile/domain/usecases/get_current_profile_usecase.dart';
import '/features/profile/domain/usecases/update_profile_role_usecase.dart';
import '/features/profile/domain/usecases/update_profile_usecase.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Services
  final secureStorageService = SecureStorageService();
  await secureStorageService.init();
  getIt.registerSingleton<SecureStorageService>(secureStorageService);
  getIt.registerSingleton<BiometricService>(BiometricService());
  getIt.registerSingleton<ImagePickerService>(ImagePickerService());
  getIt.registerSingleton<CloudinaryService>(CloudinaryService(
    cloudName: Env.cloudinaryCloudName,
    uploadPreset: Env.cloudinaryUploadPreset,
  ));
  if (Env.hasGeminiApiKey) {
    getIt.registerSingleton<GeminiService>(GeminiService(Env.geminiApiKey));
  }

  getIt.registerSingleton<SupabaseClient>(Supabase.instance.client);

  // ─── Auth ───
  getIt.registerSingleton<AuthRemoteDataSource>(
    AuthRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );
  getIt.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(
      remoteDataSource: getIt<AuthRemoteDataSource>(),
      supabaseClient: getIt<SupabaseClient>(),
      storageService: getIt<SecureStorageService>(),
    ),
  );

  // ─── Profile ───
  getIt.registerSingleton<ProfileRemoteDataSource>(
    ProfileRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );
  getIt.registerSingleton<ProfileRepository>(
    ProfileRepositoryImpl(remoteDataSource: getIt<ProfileRemoteDataSource>()),
  );
  getIt.registerSingleton<GetCurrentProfileUseCase>(
    GetCurrentProfileUseCase(getIt<ProfileRepository>()),
  );
  getIt.registerSingleton<UpdateProfileRoleUseCase>(
    UpdateProfileRoleUseCase(getIt<ProfileRepository>()),
  );
  getIt.registerSingleton<UpdateProfileUseCase>(
    UpdateProfileUseCase(getIt<ProfileRepository>()),
  );

  // ─── Category ───
  getIt.registerSingleton<CategoryRemoteDataSource>(
    CategoryRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );
  getIt.registerSingleton<CategoryRepository>(
    CategoryRepositoryImpl(remoteDataSource: getIt<CategoryRemoteDataSource>()),
  );
  getIt.registerSingleton<GetCategoriesUseCase>(
    GetCategoriesUseCase(getIt<CategoryRepository>()),
  );

  // ─── Business ───
  getIt.registerSingleton<BusinessRemoteDataSource>(
    BusinessRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );
  getIt.registerSingleton<BusinessRepository>(
    BusinessRepositoryImpl(remoteDataSource: getIt<BusinessRemoteDataSource>()),
  );
  getIt.registerSingleton<GetMyBusinessesUseCase>(
    GetMyBusinessesUseCase(getIt<BusinessRepository>()),
  );
  getIt.registerSingleton<CreateBusinessUseCase>(
    CreateBusinessUseCase(getIt<BusinessRepository>()),
  );

  // ─── Offering ───
  getIt.registerSingleton<OfferingRemoteDataSource>(
    OfferingRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );
  getIt.registerSingleton<OfferingRepository>(
    OfferingRepositoryImpl(remoteDataSource: getIt<OfferingRemoteDataSource>()),
  );
  getIt.registerSingleton<GetOfferingsUseCase>(
    GetOfferingsUseCase(getIt<OfferingRepository>()),
  );
  getIt.registerSingleton<CreateOfferingUseCase>(
    CreateOfferingUseCase(getIt<OfferingRepository>()),
  );

  // ─── Auth Use Cases ───
  getIt.registerSingleton<LoginUsecase>(LoginUsecase(getIt<AuthRepository>()));
  getIt.registerSingleton<SignUpUsecase>(SignUpUsecase(getIt<AuthRepository>()));
  getIt.registerSingleton<GoogleLoginUsecase>(
    GoogleLoginUsecase(getIt<AuthRepository>()),
  );
  getIt.registerSingleton<BiometricLoginUsecase>(
    BiometricLoginUsecase(getIt<AuthRepository>()),
  );
  getIt.registerSingleton<LogoutUsecase>(
    LogoutUsecase(getIt<AuthRepository>()),
  );

  // ─── ViewModels ───
  getIt.registerSingleton<LoginViewModel>(
    LoginViewModel(
      loginUsecase: getIt<LoginUsecase>(),
      signUpUsecase: getIt<SignUpUsecase>(),
      googleLoginUsecase: getIt<GoogleLoginUsecase>(),
      biometricLoginUsecase: getIt<BiometricLoginUsecase>(),
      logoutUsecase: getIt<LogoutUsecase>(),
      biometricService: getIt<BiometricService>(),
    ),
  );

  getIt.registerSingleton<DashboardViewModel>(
    DashboardViewModel(
      getMyBusinessesUseCase: getIt<GetMyBusinessesUseCase>(),
      getCurrentProfileUseCase: getIt<GetCurrentProfileUseCase>(),
      updateProfileRoleUseCase: getIt<UpdateProfileRoleUseCase>(),
    ),
  );

  getIt.registerSingleton<CreateBusinessViewModel>(
    CreateBusinessViewModel(
      createBusinessUseCase: getIt<CreateBusinessUseCase>(),
      getCategoriesUseCase: getIt<GetCategoriesUseCase>(),
    ),
  );

  getIt.registerSingleton<OfferingsViewModel>(
    OfferingsViewModel(
      getOfferingsUseCase: getIt<GetOfferingsUseCase>(),
      createOfferingUseCase: getIt<CreateOfferingUseCase>(),
    ),
  );
}
