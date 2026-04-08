import 'package:flutter/material.dart';

import '/core/constants/app_constants.dart';
import '/core/di/setup_dependencies.dart';
import '/features/business/domain/entities/business_entity.dart';
import '/features/offering/domain/entities/offering_entity.dart';
import '/features/offering/presentation/viewmodels/offerings_viewmodel.dart';

class BusinessDetailPage extends StatefulWidget {
  final BusinessEntity business;

  const BusinessDetailPage({super.key, required this.business});

  @override
  State<BusinessDetailPage> createState() => _BusinessDetailPageState();
}

class _BusinessDetailPageState extends State<BusinessDetailPage> {
  late final OfferingsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<OfferingsViewModel>();
    _viewModel.addListener(_onChanged);
    _viewModel.loadOfferings(widget.business.id);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final biz = widget.business;

    return Scaffold(
      appBar: AppBar(
        title: Text(biz.name),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Business info card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.store,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                biz.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                biz.categoryName ?? 'Sin categoria',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (biz.address != null && biz.address!.isNotEmpty)
                      _infoRow(Icons.location_on, biz.address!),
                    if (biz.phone != null && biz.phone!.isNotEmpty)
                      _infoRow(Icons.phone, biz.phone!),
                    _infoRow(
                      Icons.visibility,
                      '${biz.totalVisits} visitas',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Offerings section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Productos y Servicios',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => _goToCreateOffering(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_viewModel.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_viewModel.offerings.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      const Text(
                        'Aun no tienes productos ni servicios',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _goToCreateOffering(),
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar primero'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._viewModel.offerings
                  .map((o) => _buildOfferingCard(context, o))
                  .toList(),
          ],
        ),
      ),
      floatingActionButton: _viewModel.offerings.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _goToCreateOffering(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferingCard(BuildContext context, OfferingEntity offering) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: offering.type == 'product'
                ? Colors.blue[50]
                : Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            offering.type == 'product'
                ? Icons.shopping_bag
                : Icons.design_services,
            color: offering.type == 'product' ? Colors.blue : Colors.orange,
            size: 20,
          ),
        ),
        title: Text(
          offering.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${offering.typeLabel} - ${offering.priceLabel}',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: offering.durationMin != null
            ? Text(
                '${offering.durationMin} min',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              )
            : null,
      ),
    );
  }

  void _goToCreateOffering() async {
    final result = await Navigator.pushNamed(
      context,
      AppConstants.createOfferingRoute,
      arguments: widget.business.id,
    );
    if (result == true && mounted) {
      _viewModel.loadOfferings(widget.business.id);
    }
  }
}
