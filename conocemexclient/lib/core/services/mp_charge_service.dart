import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MpChargeResult {
  final String transactionId;
  final String preferenceId;
  final String initPoint;
  final String? sandboxInitPoint;
  final double amountMxn;

  MpChargeResult({
    required this.transactionId,
    required this.preferenceId,
    required this.initPoint,
    required this.amountMxn,
    this.sandboxInitPoint,
  });
}

class MpChargeException implements Exception {
  final String code;
  final String message;
  MpChargeException(this.code, this.message);
  @override
  String toString() => 'MpChargeException($code): $message';
}

class MpChargeService {
  final SupabaseClient supabaseClient;

  MpChargeService(this.supabaseClient);

  Future<MpChargeResult> crearCobro({
    required String businessId,
    required double amountMxn,
    String? description,
  }) async {
    if (supabaseClient.auth.currentSession == null) {
      throw MpChargeException('not_authenticated', 'Inicia sesion primero.');
    }

    final FunctionResponse response;
    try {
      response = await supabaseClient.functions.invoke(
        'mp-create-charge',
        body: {
          'business_id': businessId,
          'amount_mxn': amountMxn,
          if (description != null && description.isNotEmpty) 'description': description,
        },
      );
    } on FunctionException catch (e) {
      debugPrint('[MpCharge] FunctionException: $e');
      throw MpChargeException('function_error', 'Error: ${e.details ?? e.toString()}');
    }

    if (response.status != 200) {
      final code = response.data is Map ? (response.data['error']?.toString() ?? 'unknown') : 'unknown';
      throw MpChargeException(code, 'Status ${response.status}: ${response.data}');
    }

    final data = response.data as Map<String, dynamic>;
    final initPoint = data['init_point']?.toString();
    final transactionId = data['transaction_id']?.toString();
    final preferenceId = data['preference_id']?.toString();

    if (initPoint == null || transactionId == null || preferenceId == null) {
      throw MpChargeException('invalid_response', 'Respuesta incompleta.');
    }

    return MpChargeResult(
      transactionId: transactionId,
      preferenceId: preferenceId,
      initPoint: initPoint,
      sandboxInitPoint: data['sandbox_init_point']?.toString(),
      amountMxn: (data['amount_mxn'] as num).toDouble(),
    );
  }
}
