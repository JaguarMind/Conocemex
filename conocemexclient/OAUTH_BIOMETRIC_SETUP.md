# Guía de Configuración: Google OAuth + Biometría

## 🔐 Google OAuth Setup

### Android

1. **Crear credenciales en Google Cloud Console**
   - Ve a https://console.cloud.google.com
   - Crea un nuevo proyecto
   - Ve a "Credenciales"
   - Crea credencial "OAuth 2.0 Client ID" (Android)
   - Necesitarás: package name, SHA-1 fingerprint

2. **Obtener SHA-1 Fingerprint**
```bash
# Desde el directorio del proyecto
./gradlew signingReport
```

3. **Actualizar `android/build.gradle`**
```gradle
buildscript {
    ext {
        kotlin_version = '1.8.0'
        google_play_services_version = '4.3.15'
    }
}
```

4. **Actualizar `android/app/build.gradle`**
```gradle
dependencies {
    implementation 'com.google.android.gms:play-services-auth:20.6.0'
    implementation 'androidx.biometric:biometric:1.1.0'
}

android {
    compileSdk 33
    
    defaultConfig {
        minSdk 21
        targetSdk 33
    }
}
```

5. **Actualizar AppConstants.dart**
```dart
static const String googleAndroidClientId =
    'TU_CLIENT_ID.apps.googleusercontent.com';
```

### iOS

1. **Crear credencial en Google Cloud Console**
   - Tipo: OAuth 2.0 Client ID (iOS)
   - Bundle ID: com.example.conocemexclient (o tu bundle ID)
   - Descarga el archivo plist

2. **Agregar GoogleService-Info.plist**
   - Descargalo desde Google Cloud Console
   - Arrastralo a `ios/Runner` en Xcode
   - Asegúrate de que esté en iOS target

3. **Actualizar `ios/Runner/Info.plist`**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Google OAuth -->
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>com.googleusercontent.apps.TU_CLIENT_ID</string>
            </array>
        </dict>
    </array>

    <!-- Biometría -->
    <key>NSFaceIDUsageDescription</key>
    <string>Necesitamos acceso a Face ID para autenticarte de forma segura</string>
    <key>NSBiometricsUsageDescription</key>
    <string>Necesitamos acceso a biometría para autenticarte</string>
</dict>
</plist>
```

4. **Actualizar AppConstants.dart**
```dart
static const String googleIosClientId =
    'TU_CLIENT_ID.apps.googleusercontent.com';
```

### Web (Opcional)

1. **En `web/index.html`**
```html
<script src="https://apis.google.com/js/platform.js" async defer></script>
<meta name="google-signin-client_id" content="TU_WEB_CLIENT_ID.apps.googleusercontent.com">
```

2. **Actualizar AppConstants.dart**
```dart
static const String googleWebClientId =
    'TU_WEB_CLIENT_ID.apps.googleusercontent.com';
```

## 📱 Biometría Setup

### Android
- Requiere `minSdk 21` o superior
- Los permisos están automáticamente en AndroidManifest.xml por `local_auth`

### iOS
- Requiere iOS 11+ para Face ID
- Requiere iOS 13+ para biometría en general
- Asegúrate de que tengas los permisos en Info.plist

## 🧪 Pruebas

### Login con Email/Contraseña
1. La API debe tener endpoint `/auth/login` que reciba:
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

2. Respuesta esperada:
```json
{
  "access_token": "eyJhbGc...",
  "refresh_token": "eyJhbGc...",
  "user": {
    "id": "user_id",
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "profile_picture": "https://...",
    "created_at": "2024-01-01T00:00:00Z"
  }
}
```

### Login con Google
1. Click en "Iniciar con Google"
2. Selecciona cuenta
3. Se enviará el token a `/auth/google`

### Login con Biometría
1. Primero debe haber un usuario autenticado
2. Click en "Iniciar con Biometría"
3. Autentica con huella o cara
4. Se accede con los datos almacenados localmente

## ⚠️ Troubleshooting

### Google Sign In no funciona en Android
- Verifica SHA-1 fingerprint coincide en Google Cloud Console
- Revisa package name exacto
- Limpia gradle: `./gradlew clean`

### Google Sign In no funciona en iOS
- Verifica bundle ID en Google Cloud Console
- Revisa Info.plist está correctamente formado
- Ejecuta: `cd ios && pod update && cd ..`

### Biometría no funciona
- Verifica minSdk >= 21 (Android)
- Verifica iOS >= 11
- Comprueba permisos en AndroidManifest.xml e Info.plist
- En emulador/simulator puede no funcionar

### Tokens no se guardan
- Verifica SharedPreferences está inicializado
- Revisa que SecureStorageService.init() se ejecute en main
- En debug, los datos van a ubicación específica del emulador

## 🚀 Lint & Build

```bash
# Format code
dart format lib/

# Analyze code
flutter analyze

# Build APK
flutter build apk

# Build iOS
flutter build ios

# Build Web
flutter build web
```

## 📞 Soporte

Si encuentras problemas:
1. Revisar logs: `flutter logs`
2. Limpiar caché: `flutter clean && flutter pub get`
3. Recrear native files: `flutter pub get && flutter pub upgrade`
