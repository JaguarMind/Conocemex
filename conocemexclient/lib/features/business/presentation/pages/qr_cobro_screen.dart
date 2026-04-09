import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/services/mp_charge_service.dart';
import '/l10n/app_localizations.dart';

enum CobroStatus { pending, completed, failed, refunded }

class QrCobroScreen extends StatefulWidget {
  final MpChargeResult charge;
  const QrCobroScreen({super.key, required this.charge});

  @override
  State<QrCobroScreen> createState() => _QrCobroScreenState();
}

class _QrCobroScreenState extends State<QrCobroScreen> {
  static const _darkBlue = Color(0xFF001F3F);
  static const _primaryGreen = Color(0xFF00DF5F);

  CobroStatus _status = CobroStatus.pending;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _subscribeToTransaction();
  }

  void _subscribeToTransaction() {
    _channel = Supabase.instance.client
        .channel('transaction:${widget.charge.transactionId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.charge.transactionId,
          ),
          callback: (payload) {
            final status = payload.newRecord['status']?.toString();
            if (status == null || !mounted) return;
            setState(() {
              switch (status) {
                case 'completed': _status = CobroStatus.completed;
                case 'failed': _status = CobroStatus.failed;
                case 'refunded': _status = CobroStatus.refunded;
                default: _status = CobroStatus.pending;
              }
            });
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: _darkBlue), onPressed: () => Navigator.pop(context)),
        title: Text(l.chargeQr, style: const TextStyle(fontWeight: FontWeight.w800, color: _darkBlue, fontSize: 17)),
        centerTitle: true,
      ),
      body: Center(
        child: _status == CobroStatus.completed
            ? _buildSuccess(l)
            : _status == CobroStatus.failed
                ? _buildFailed(l)
                : _buildPending(l),
      ),
    );
  }

  Widget _buildPending(AppLocalizations l) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Monto
          Text(
            '\$${widget.charge.amountMxn.toStringAsFixed(2)} MXN',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: _darkBlue),
          ),
          const SizedBox(height: 24),

          // QR
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 6)),
              ],
            ),
            child: QrImageView(
              data: widget.charge.initPoint,
              version: QrVersions.auto,
              size: 260,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: _darkBlue),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: _darkBlue),
            ),
          ),
          const SizedBox(height: 28),

          // Spinner + texto
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _primaryGreen)),
              const SizedBox(width: 12),
              Text(l.waitingPayment, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _darkBlue.withValues(alpha: 0.6))),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l.scanQrInstruction,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _darkBlue.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
              color: _primaryGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.check_circle, color: _primaryGreen, size: 56),
          ),
          const SizedBox(height: 20),
          Text(l.paymentReceived, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _darkBlue)),
          const SizedBox(height: 8),
          Text(
            '\$${widget.charge.amountMxn.toStringAsFixed(2)} MXN',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _darkBlue.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen, foregroundColor: _darkBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              child: Text(l.done, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailed(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.error, color: Colors.red, size: 56),
          ),
          const SizedBox(height: 20),
          Text(l.paymentFailed, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _darkBlue)),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen, foregroundColor: _darkBlue,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child: Text(l.retry, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
