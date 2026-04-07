#!/bin/bash

echo "🔨 Generando archivos de código (Retrofit, JSON Serializable)..."
echo ""

# Ensure we're in the project root
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml no encontrado. Ejecuta este script desde la raíz del proyecto."
    exit 1
fi

echo "✅ Instalando dependencias..."
flutter pub get

echo ""
echo "✅ Ejecutando build_runner..."
flutter pub run build_runner build --delete-conflicting-outputs

echo ""
echo "✅ ¡Generación completada!"
echo ""
echo "Próximos pasos:"
echo "1. Actualiza AppConstants con tus URLs de API"
echo "2. Configura Google OAuth según OAUTH_BIOMETRIC_SETUP.md"
echo "3. Ejecuta: flutter run"
