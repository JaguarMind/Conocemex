import 'package:flutter/material.dart';

import '/core/di/setup_dependencies.dart';
import '/core/services/mp_charge_service.dart';
import '/features/business/presentation/pages/qr_cobro_screen.dart';
import '/features/offering/domain/entities/offering_entity.dart';
import '/features/offering/presentation/viewmodels/offerings_viewmodel.dart';
import '/l10n/app_localizations.dart';

class RegistrarVentaPage extends StatefulWidget {
  final String businessId;
  final String businessName;

  const RegistrarVentaPage({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  @override
  State<RegistrarVentaPage> createState() => _RegistrarVentaPageState();
}

class _RegistrarVentaPageState extends State<RegistrarVentaPage> {
  static const _darkBlue = Color(0xFF001F3F);
  static const _primaryGreen = Color(0xFF00DF5F);
  static const _bgGrey = Color(0xFFF3F3F4);

  late final OfferingsViewModel _offeringsVM;
  bool _loading = true;
  bool _generating = false;

  // Carrito: offeringId → cantidad
  final Map<String, int> _cart = {};

  @override
  void initState() {
    super.initState();
    _offeringsVM = getIt<OfferingsViewModel>();
    _offeringsVM.addListener(_onChanged);
    _offeringsVM.loadOfferings(widget.businessId);
  }

  @override
  void dispose() {
    _offeringsVM.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() => _loading = _offeringsVM.isLoading);
  }

  double get _total {
    double sum = 0;
    for (final entry in _cart.entries) {
      final offering = _offeringsVM.offerings.firstWhere((o) => o.id == entry.key, orElse: () => _offeringsVM.offerings.first);
      sum += offering.priceMxn * entry.value;
    }
    return sum;
  }

  int get _itemCount => _cart.values.fold(0, (a, b) => a + b);

  String _buildDescription() {
    final parts = <String>[];
    for (final entry in _cart.entries) {
      if (entry.value <= 0) continue;
      final offering = _offeringsVM.offerings.firstWhere((o) => o.id == entry.key);
      parts.add('${offering.name} x${entry.value}');
    }
    final desc = parts.join(', ');
    return desc.length > 240 ? '${desc.substring(0, 237)}...' : desc;
  }

  void _addToCart(String offeringId) {
    setState(() => _cart[offeringId] = (_cart[offeringId] ?? 0) + 1);
  }

  void _removeFromCart(String offeringId) {
    setState(() {
      final current = _cart[offeringId] ?? 0;
      if (current <= 1) {
        _cart.remove(offeringId);
      } else {
        _cart[offeringId] = current - 1;
      }
    });
  }

  Future<void> _generateQr() async {
    if (_total < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.chargeMinAmount), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _generating = true);
    final l = AppLocalizations.of(context)!;

    try {
      final service = getIt<MpChargeService>();
      final result = await service.crearCobro(
        businessId: widget.businessId,
        amountMxn: _total,
        description: _buildDescription(),
      );

      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => QrCobroScreen(charge: result)));
    } on MpChargeException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final offerings = _offeringsVM.offerings;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: _darkBlue), onPressed: () => Navigator.pop(context)),
        title: Text(l.registerSale, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _darkBlue)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primaryGreen))
          : offerings.isEmpty
              ? Center(child: Text(l.noProductsYet, style: TextStyle(color: _darkBlue.withValues(alpha: 0.4))))
              : Column(
                  children: [
                    // Nombre del negocio
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      color: _bgGrey,
                      child: Text(widget.businessName, style: TextStyle(fontWeight: FontWeight.w700, color: _darkBlue.withValues(alpha: 0.6), fontSize: 13)),
                    ),

                    // Lista de productos
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: offerings.length,
                        itemBuilder: (_, i) => _buildOfferingItem(offerings[i]),
                      ),
                    ),
                  ],
                ),

      // Bottom bar con total + boton
      bottomNavigationBar: _itemCount > 0
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4))],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Resumen
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$_itemCount ${l.items}', style: TextStyle(fontWeight: FontWeight.w600, color: _darkBlue.withValues(alpha: 0.5))),
                          Text('\$${_total.toStringAsFixed(2)} MXN', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _darkBlue)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Boton
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _generating ? null : _generateQr,
                          icon: _generating
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _darkBlue))
                              : const Icon(Icons.qr_code_2, size: 20),
                          label: Text(_generating ? l.generating : l.generateQr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryGreen, foregroundColor: _darkBlue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 4, shadowColor: _primaryGreen.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildOfferingItem(OfferingEntity offering) {
    final qty = _cart[offering.id] ?? 0;
    final isProduct = offering.type == 'product';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: qty > 0 ? _primaryGreen.withValues(alpha: 0.3) : _darkBlue.withValues(alpha: 0.06)),
      ),
      color: qty > 0 ? _primaryGreen.withValues(alpha: 0.04) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Icono
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isProduct ? Colors.blue.withValues(alpha: 0.08) : Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isProduct ? Icons.shopping_bag : Icons.design_services,
                color: isProduct ? Colors.blue : Colors.orange, size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(offering.name, style: const TextStyle(fontWeight: FontWeight.w700, color: _darkBlue, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('\$${offering.priceMxn.toStringAsFixed(2)} MXN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primaryGreen)),
                ],
              ),
            ),
            // Controles de cantidad
            if (qty == 0)
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: () => _addToCart(offering.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen, foregroundColor: _darkBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  child: const Icon(Icons.add, size: 20),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: _bgGrey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(qty == 1 ? Icons.delete_outline : Icons.remove, size: 18, color: qty == 1 ? Colors.red : _darkBlue),
                      onPressed: () => _removeFromCart(offering.id),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                    ),
                    SizedBox(
                      width: 28,
                      child: Text('$qty', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, color: _darkBlue, fontSize: 16)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18, color: _primaryGreen),
                      onPressed: () => _addToCart(offering.id),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
