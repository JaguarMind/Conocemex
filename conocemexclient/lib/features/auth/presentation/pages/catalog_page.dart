import 'package:flutter/material.dart';

import '/core/constants/app_constants.dart';
import '/core/di/setup_dependencies.dart';
import '/features/business/domain/entities/business_entity.dart';
import '/features/business/presentation/viewmodels/dashboard_viewmodel.dart';
import '/features/offering/domain/entities/offering_entity.dart';
import '/features/offering/presentation/viewmodels/offerings_viewmodel.dart';

class CatalogPage extends StatefulWidget {
  final BusinessEntity? initialBusiness;

  const CatalogPage({super.key, this.initialBusiness});

  @override
  State<CatalogPage> createState() => CatalogPageState();
}

class CatalogPageState extends State<CatalogPage> {
  static const _darkBlue = Color(0xFF001F3F);
  static const _primaryGreen = Color(0xFF00DF5F);
  static const _bgGrey = Color(0xFFF3F3F4);

  BusinessEntity? _selectedBusiness;
  late final OfferingsViewModel _offeringsVM;
  late final DashboardViewModel _dashVM;

  @override
  void initState() {
    super.initState();
    _offeringsVM = getIt<OfferingsViewModel>();
    _dashVM = getIt<DashboardViewModel>();
    _offeringsVM.addListener(_onChanged);
    _dashVM.addListener(_onChanged);

    if (widget.initialBusiness != null) {
      _selectedBusiness = widget.initialBusiness;
      _offeringsVM.loadOfferings(_selectedBusiness!.id);
    }
  }

  @override
  void dispose() {
    _offeringsVM.removeListener(_onChanged);
    _dashVM.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  /// Llamado desde MainShellPage cuando el usuario selecciona un negocio desde Home
  void selectBusiness(BusinessEntity business) {
    setState(() => _selectedBusiness = business);
    _offeringsVM.loadOfferings(business.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Catalogo', style: TextStyle(fontWeight: FontWeight.w800, color: _darkBlue)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // ─── Selector de negocio ───
          _buildBusinessSelector(),

          // ─── Contenido ───
          Expanded(
            child: _selectedBusiness == null
                ? _buildSelectPrompt()
                : _buildOfferingsList(),
          ),
        ],
      ),
      floatingActionButton: _selectedBusiness != null && _offeringsVM.offerings.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _goToCreateOffering(),
              backgroundColor: _primaryGreen,
              foregroundColor: _darkBlue,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBusinessSelector() {
    final businesses = _dashVM.businesses;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _bgGrey,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBusiness?.id,
          hint: Row(
            children: [
              Icon(Icons.store, size: 20, color: _darkBlue.withValues(alpha: 0.4)),
              const SizedBox(width: 10),
              Text(
                'Selecciona un negocio',
                style: TextStyle(
                  color: _darkBlue.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: _darkBlue.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(14),
          items: businesses.map((biz) {
            return DropdownMenuItem<String>(
              value: biz.id,
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: _primaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.store, color: _primaryGreen, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(biz.name, style: const TextStyle(fontWeight: FontWeight.w700, color: _darkBlue, fontSize: 14)),
                        Text(biz.categoryName ?? '', style: TextStyle(fontSize: 11, color: _darkBlue.withValues(alpha: 0.4))),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (id) {
            if (id == null) return;
            final biz = businesses.firstWhere((b) => b.id == id);
            selectBusiness(biz);
          },
        ),
      ),
    );
  }

  Widget _buildSelectPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: _primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.grid_view, size: 36, color: _primaryGreen),
            ),
            const SizedBox(height: 20),
            const Text(
              'Selecciona un negocio',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _darkBlue),
            ),
            const SizedBox(height: 8),
            Text(
              'Elige uno de tus negocios para ver\ny gestionar sus productos y servicios.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _darkBlue.withValues(alpha: 0.45), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferingsList() {
    if (_offeringsVM.isLoading) {
      return const Center(child: CircularProgressIndicator(color: _primaryGreen));
    }

    if (_offeringsVM.offerings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: _primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.inventory_2_outlined, size: 36, color: _primaryGreen),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sin productos aun',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _darkBlue),
              ),
              const SizedBox(height: 8),
              Text(
                'Agrega productos o servicios\na ${_selectedBusiness?.name ?? "tu negocio"}.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: _darkBlue.withValues(alpha: 0.45)),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _goToCreateOffering(),
                icon: const Icon(Icons.add),
                label: const Text('Agregar producto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: _darkBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _offeringsVM.loadOfferings(_selectedBusiness!.id),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: _offeringsVM.offerings.length,
        itemBuilder: (context, i) => _buildOfferingCard(_offeringsVM.offerings[i]),
      ),
    );
  }

  Widget _buildOfferingCard(OfferingEntity offering) {
    final isProduct = offering.type == 'product';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: _darkBlue.withValues(alpha: 0.06)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: isProduct
                    ? Colors.blue.withValues(alpha: 0.08)
                    : Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isProduct ? Icons.shopping_bag : Icons.design_services,
                color: isProduct ? Colors.blue : Colors.orange,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(offering.name, style: const TextStyle(fontWeight: FontWeight.w700, color: _darkBlue, fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(
                    '${offering.typeLabel} - ${offering.priceLabel}',
                    style: TextStyle(fontSize: 13, color: _darkBlue.withValues(alpha: 0.45)),
                  ),
                ],
              ),
            ),
            if (offering.durationMin != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _bgGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${offering.durationMin} min', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _darkBlue.withValues(alpha: 0.5))),
              ),
          ],
        ),
      ),
    );
  }

  void _goToCreateOffering() async {
    if (_selectedBusiness == null) return;
    final result = await Navigator.pushNamed(
      context,
      AppConstants.createOfferingRoute,
      arguments: _selectedBusiness!.id,
    );
    if (result == true && mounted) {
      _offeringsVM.loadOfferings(_selectedBusiness!.id);
    }
  }
}
