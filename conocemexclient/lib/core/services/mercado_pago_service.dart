import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MpOauthException implements Exception {
  final String code;
  final String message;

  MpOauthException(this.code, this.message);

  @override
  String toString() => 'MpOauthException($code): $message';
}

class MercadoPagoService {
  final SupabaseClient supabaseClient;

  MercadoPagoService(this.supabaseClient);

  /// Inicia el flujo OAuth de Mercado Pago para el [businessId].
  /// Abre el navegador externo con la pantalla de autorizacion de MP.
  Future<bool> conectarMercadoPago(String businessId) async {
    // 1. Verificar sesion
    final session = supabaseClient.auth.currentSession;
    if (session == null) {
      throw MpOauthException('not_authenticated', 'Necesitas iniciar sesion.');
    }

    // 2. Llamar a la Edge Function
    final FunctionResponse response;
    try {
      response = await supabaseClient.functions.invoke(
        'mp-oauth-start',
        body: {'business_id': businessId},
      );
    } on FunctionException catch (e) {
      debugPrint('[MercadoPago] FunctionException: $e');
      throw MpOauthException('function_error', 'Error al conectar: ${e.details ?? e.toString()}');
    }

    // 3. Validar respuesta
    if (response.status != 200) {
      final data = response.data;
      final errorCode = data is Map ? (data['error']?.toString() ?? 'unknown') : 'unknown';

      switch (errorCode) {
        case 'not_business_owner':
          throw MpOauthException(errorCode, 'No eres dueno de este negocio.');
        case 'business_not_found':
          throw MpOauthException(errorCode, 'El negocio no fue encontrado.');
        case 'business_id_required':
          throw MpOauthException(errorCode, 'Falta el ID del negocio.');
        default:
          throw MpOauthException(errorCode, 'Error del servidor: $data');
      }
    }

    final data = response.data;
    if (data is! Map || data['authorization_url'] is! String) {
      throw MpOauthException('invalid_response', 'Respuesta invalida del servidor.');
    }

    final authUrl = data['authorization_url'] as String;

    // 4. Abrir en navegador externo (NO WebView)
    final uri = Uri.parse(authUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched) {
      throw MpOauthException('launch_failed', 'No se pudo abrir el navegador.');
    }

    return true;
  }

  /// Desvincula la cuenta de MP de un negocio.
  Future<void> disconnectMercadoPago(String businessId) async {
    try {
      await supabaseClient
          .from('mp_accounts')
          .delete()
          .eq('business_id', businessId);
    } catch (e) {
      debugPrint('[MercadoPago] Disconnect error: $e');
      throw MpOauthException('disconnect_failed', 'Error al desvincular: $e');
    }
  }

  /// Verifica si un negocio ya tiene cuenta de MP conectada.
  Future<bool> isConnected(String businessId) async {
    try {
      final row = await supabaseClient
          .from('mp_accounts')
          .select('id')
          .eq('business_id', businessId)
          .maybeSingle();

      return row != null;
    } catch (e) {
      debugPrint('[MercadoPago] Error checking connection: $e');
      return false;
    }
  }
}
