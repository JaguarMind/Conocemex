import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/core/constants/app_constants.dart';
import '/core/di/setup_dependencies.dart';
import '/core/routes/app_routes.dart';
import '/features/business/domain/entities/business_entity.dart';
import '/features/business/presentation/viewmodels/dashboard_viewmodel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _darkBlue = Color(0xFF001F3F);
  static const _primaryGreen = Color(0xFF00DF5F);

  @override
  void initState() {
    super.initState();
    getIt<DashboardViewModel>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Mi Panel',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: _darkBlue,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: ChangeNotifierProvider<DashboardViewModel>.value(
        value: getIt<DashboardViewModel>(),
        child: Consumer<DashboardViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        viewModel.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => viewModel.loadDashboard(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (viewModel.businesses.isEmpty) {
              return _buildEmptyState(context);
            }

            return _buildBusinessList(context, viewModel.businesses);
          },
        ),
      ),
      floatingActionButton: Consumer<DashboardViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.businesses.isEmpty) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => _goToCreateBusiness(context),
            backgroundColor: _primaryGreen,
            foregroundColor: _darkBlue,
            icon: const Icon(Icons.add),
            label: const Text(
              'Agregar negocio',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: _primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.store, size: 44, color: _primaryGreen),
            ),
            const SizedBox(height: 24),
            const Text(
              'Bienvenido a Conocemex',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _darkBlue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Registra tu negocio para que turistas\nde todo el mundo puedan descubrirte.',
              style: TextStyle(
                fontSize: 15,
                color: _darkBlue.withValues(alpha: 0.45),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _goToCreateBusiness(context),
              icon: const Icon(Icons.add),
              label: const Text('Agregar mi primer negocio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: _darkBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessList(
      BuildContext context, List<BusinessEntity> businesses) {
    return RefreshIndicator(
      onRefresh: () => getIt<DashboardViewModel>().refreshBusinesses(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: businesses.length,
        itemBuilder: (context, index) {
          final biz = businesses[index];
          return _buildBusinessCard(context, biz);
        },
      ),
    );
  }

  Widget _buildBusinessCard(BuildContext context, BusinessEntity biz) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: _darkBlue.withValues(alpha: 0.06)),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => AppRoutes.goToBusinessDetail(context, biz),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.store, color: _primaryGreen, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      biz.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _darkBlue,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      biz.categoryName ?? 'Sin categoria',
                      style: TextStyle(
                        fontSize: 13,
                        color: _darkBlue.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (biz.averageRating != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 16, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          biz.averageRating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: _darkBlue,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: biz.isActive
                          ? _primaryGreen.withValues(alpha: 0.12)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      biz.isActive ? 'Activo' : 'Inactivo',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color:
                            biz.isActive ? _primaryGreen : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right,
                  color: _darkBlue.withValues(alpha: 0.2)),
            ],
          ),
        ),
      ),
    );
  }

  void _goToCreateBusiness(BuildContext context) async {
    final result = await Navigator.pushNamed(
      context,
      AppConstants.createBusinessRoute,
    );
    if (result == true && mounted) {
      getIt<DashboardViewModel>().refreshBusinesses();
    }
  }
}
