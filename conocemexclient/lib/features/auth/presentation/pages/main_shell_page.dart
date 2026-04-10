import 'package:flutter/material.dart';

import '/core/di/setup_dependencies.dart';
import '/core/services/locale_service.dart';
import '/features/auth/presentation/pages/catalog_page.dart';
import '/features/auth/presentation/pages/communities_page.dart';
import '/features/auth/presentation/pages/home_page.dart';
import '/features/business/domain/entities/business_entity.dart';
import '/features/business/presentation/pages/sales_history_page.dart';
import '/features/business/presentation/viewmodels/dashboard_viewmodel.dart';
import '/features/profile/presentation/pages/profile_page.dart';
import '/l10n/app_localizations.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  /// Permite acceder al estado desde hijos via MainShellPage.of(context)
  static _MainShellPageState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MainShellPageState>();
  }

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  static const _primaryGreen = Color(0xFF00DF5F);
  static const _darkBlue = Color(0xFF001F3F);

  int _currentIndex = 0;

  // Negocio seleccionado para el tab Catalog
  BusinessEntity? _selectedBusiness;

  final _catalogKey = GlobalKey<CatalogPageState>();

  @override
  void initState() {
    super.initState();
    // Cargar perfil + negocios + idioma al entrar a la shell
    getIt<DashboardViewModel>().loadDashboard();
    getIt<LocaleService>().loadFromSupabase();
  }

  /// Llamado desde HomePage cuando el usuario toca un negocio
  void goToCatalog(BusinessEntity business) {
    setState(() {
      _selectedBusiness = business;
      _currentIndex = 1;
    });
    // Notificar al CatalogPage que cambie de negocio
    _catalogKey.currentState?.selectBusiness(business);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomePage(),
          CatalogPage(
            key: _catalogKey,
            initialBusiness: _selectedBusiness,
          ),
          const SalesHistoryPage(),
          const CommunitiesPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home, AppLocalizations.of(context)!.navHome),
                _buildCatalogItem(),
                _buildNavItem(2, Icons.receipt_long_outlined, Icons.receipt_long, AppLocalizations.of(context)!.sales),
                _buildNavItem(3, Icons.chat_bubble_outline, Icons.chat_bubble, AppLocalizations.of(context)!.chat),
                _buildNavItem(4, Icons.person_outline, Icons.person, AppLocalizations.of(context)!.navProfile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? _primaryGreen : _darkBlue.withValues(alpha: 0.35),
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? _primaryGreen : _darkBlue.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogItem() {
    final isActive = _currentIndex == 1;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 1),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive ? _primaryGreen.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isActive ? Icons.grid_view : Icons.grid_view_outlined,
              color: isActive ? _primaryGreen : _darkBlue.withValues(alpha: 0.35),
              size: 26,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.navCatalog,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? _primaryGreen : _darkBlue.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}
