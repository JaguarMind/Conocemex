import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/core/di/setup_dependencies.dart';
import '/core/services/mp_charge_service.dart';
import '/features/business/presentation/pages/qr_cobro_screen.dart';
import '/l10n/app_localizations.dart';

class CobrarScreen extends StatefulWidget {
  final String businessId;
  const CobrarScreen({super.key, required this.businessId});

  @override
  State<CobrarScreen> createState() => _CobrarScreenState();
}

class _CobrarScreenState extends State<CobrarScreen> {
  static const _darkBlue = Color(0xFF001F3F);
  static const _primaryGreen = Color(0xFF00DF5F);
  static const _bgGrey = Color(0xFFF3F3F4);

  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _onGenerar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final l = AppLocalizations.of(context)!;

    try {
      final amount = double.parse(_amountCtrl.text.replaceAll(',', '.'));
      final service = getIt<MpChargeService>();
      final result = await service.crearCobro(
        businessId: widget.businessId,
        amountMxn: amount,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );

      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => QrCobroScreen(charge: result)));
    } on MpChargeException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMsg(e.code, l)), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _errorMsg(String code, AppLocalizations l) {
    switch (code) {
      case 'mp_not_connected': return l.mpNotConnected;
      case 'amount_too_low': return l.chargeMinAmount;
      case 'not_business_owner': return l.errorCreateBusiness;
      default: return l.errorUnexpected;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: _darkBlue), onPressed: () => Navigator.pop(context)),
        title: Text(l.charge, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _darkBlue)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icono
              Center(
                child: Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: _primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.qr_code_2, size: 36, color: _primaryGreen),
                ),
              ),
              const SizedBox(height: 24),

              // Label monto
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Text(l.chargeAmount, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _darkBlue.withValues(alpha: 0.5), letterSpacing: 1.5)),
              ),

              // Input monto
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: _darkBlue),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  prefixStyle: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: _darkBlue.withValues(alpha: 0.5)),
                  suffixText: 'MXN',
                  suffixStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _darkBlue.withValues(alpha: 0.35)),
                  filled: true, fillColor: _bgGrey,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _primaryGreen, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return l.required;
                  final n = double.tryParse(v.replaceAll(',', '.'));
                  if (n == null) return l.invalidPrice;
                  if (n < 5) return l.chargeMinAmount;
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Descripcion
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Text(l.chargeDescription, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _darkBlue.withValues(alpha: 0.5), letterSpacing: 1.5)),
              ),
              TextFormField(
                controller: _descCtrl,
                maxLength: 100,
                style: const TextStyle(fontWeight: FontWeight.w600, color: _darkBlue),
                decoration: InputDecoration(
                  hintText: l.chargeDescHint,
                  hintStyle: TextStyle(color: _darkBlue.withValues(alpha: 0.25), fontWeight: FontWeight.w500),
                  filled: true, fillColor: _bgGrey,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primaryGreen, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
              const SizedBox(height: 28),

              // Boton
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _onGenerar,
                  icon: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _darkBlue))
                      : const Icon(Icons.qr_code_2),
                  label: Text(_loading ? l.generating : l.generateQr, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen, foregroundColor: _darkBlue,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 8, shadowColor: _primaryGreen.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
