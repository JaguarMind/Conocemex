# Conocemex - Arquitectura MVVM + Clean Architecture

## 📋 Descripción General

Proyecto Flutter con arquitectura profesional MVVM + Clean Architecture, dividida por módulos verticales.

## 🏗️ Estructura de Carpetas

```
lib/
├── core/
│   ├── config/           # Configuraciones de la app
│   ├── constants/        # Constantes globales
│   ├── di/              # Inyección de dependencias (GetIt)
│   ├── extensions/      # Excepciones y extensiones
│   ├── network/         # Configuración HTTP (Retrofit, Dio)
│   ├── routes/          # Rutas y navegación
│   └── services/        # Servicios globales (Biometría, Storage)
│
├── features/
│   └── auth/            # Módulo de autenticación
│       ├── data/        # Capa de datos
│       │   ├── datasources/    # Fuentes remotas/locales
│       │   ├── models/         # DTOs (serializables)
│       │   └── repositories/   # Implementación de repositorios
│       ├── domain/      # Capa de dominio (lógica pura)
│       │   ├── entities/       # Objetos del dominio
│       │   ├── repositories/   # Interfaces de repositorios
│       │   └── usecases/       # Casos de uso
│       └── presentation/# Capa de presentación
│           ├── pages/          # Pantallas completas
│           ├── viewmodels/     # ViewModels
│           └── widgets/        # Componentes reutilizables
│
└── main.dart           # Punto de entrada
```

## 🔐 Autenticación

### Métodos soportados:
1. **Email + Contraseña** - Login tradicional
2. **Google OAuth** - Autenticación social
3. **Biometría** - Huella dactilar / Reconocimiento facial

## 🛠️ Configuración Requerida

### Google OAuth (Android)
En `android/app/build.gradle`:
```gradle
dependencies {
    implementation 'com.google.android.gms:play-services-auth:20.6.0'
}
```

En `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### Google OAuth (iOS)
En `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

### Biometría
En `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
<uses-permission android:name="android.permission.USE_FINGERPRINT" />
```

En `ios/Runner/Info.plist`:
```xml
<key>NSFaceIDUsageDescription</key>
<string>Necesitamos acceso a Face ID para autenticarte de forma segura</string>
<key>NSBiometricsUsageDescription</key>
<string>Necesitamos acceso a biometría para autenticarte</string>
```

## 📦 Dependencias Principales

- **dio** - Cliente HTTP
- **retrofit** - API REST con type-safety
- **provider** - State management
- **get_it** - Inyección de dependencias
- **google_sign_in** - Autenticación con Google
- **local_auth** - Autenticación biométrica
- **shared_preferences** - Almacenamiento local
- **json_serializable** - Serialización JSON
- **freezed** - Generación de código

## 🚀 Pasos de Usar

### 1. Generar archivos de Retrofit y Serialización
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. Compilar el proyecto
```bash
flutter pub get
flutter run
```

## 📝 Cambios Requeridos

### Actualizar AppConstants
En `lib/core/constants/app_constants.dart`:
- Cambiar `baseUrl` con tu URL de API
- Configurar Google OAuth IDs
- Ajustar tiempos de conexión

### Configurar Firebase/Google Cloud
1. Crear proyecto en Google Cloud Console
2. Habilitar API de Google Sign In
3. Crear credenciales OAuth
4. Actualizar IDs en la app

## 🔄 Flujo de Autenticación

```
LoginPage
    ↓
LoginViewModel
    ↓
    ├→ LoginUsecase → AuthRepository → RemoteDataSource → API
    ├→ GoogleLoginUsecase → OAuth → RemoteDataSource → API
    └→ BiometricLoginUsecase → BiometricService → Storage
    ↓
SecureStorageService (guarda tokens y usuario)
    ↓
HomePage (acceso concedido)
```

## 🔒 Seguridad

- Tokens almacenados en `shared_preferences` (considerar SQLCipher en producción)
- OAuth flow seguro con verificación de tokens
- Biometría solo para validar credenciales almacenadas
- Interceptors para agregar tokens automáticamente

## 📱 Próximas Características

- [ ] Módulo de registro
- [ ] Recuperación de contraseña
- [ ] 2FA (Two-Factor Authentication)
- [ ] Sincronización en tiempo real con WebSockets
- [ ] Caché local con Hive/Isar

## 📚 Referencias

- [Clean Architecture](https://resocoder.com/flutter-clean-architecture)
- [Provider Pattern](https://pub.dev/packages/provider)
- [Retrofit Documentation](https://pub.dev/packages/retrofit)
- [Google Sign In](https://pub.dev/packages/google_sign_in)
- [Local Auth](https://pub.dev/packages/local_auth)
