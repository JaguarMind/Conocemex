import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/core/constants/app_constants.dart';
import '/core/di/setup_dependencies.dart';
import '/core/routes/app_routes.dart';
import '/features/profile/domain/entities/profile_entity.dart';
import '/features/profile/domain/usecases/get_current_profile_usecase.dart';
import '../viewmodels/login_viewmodel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Future<ProfileEntity?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = getIt<GetCurrentProfileUseCase>()();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: Consumer<LoginViewModel>(
        builder: (context, viewModel, _) {
          final user = viewModel.auth?.user;

          return FutureBuilder<ProfileEntity?>(
            future: _profileFuture,
            builder: (context, snapshot) {
              final profile = snapshot.data;
              final profileName = profile?.fullName.trim() ?? '';
              final authName =
                  '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();
              final displayName = profileName.isNotEmpty
                  ? profileName
                  : authName;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                AppConstants.appLogoPath,
                                width: 90,
                                height: 90,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '¡Bienvenido, $displayName!',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              user?.email ?? '',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildInfoCard(context, 'Nombre', displayName),
                    const SizedBox(height: 12),
                    _buildInfoCard(context, 'Rol', profile?.role ?? 'turista'),
                    const SizedBox(height: 12),
                    _buildInfoCard(context, 'Correo', user?.email ?? ''),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      'Teléfono',
                      profile?.phone ?? 'No registrado',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      'Nacionalidad',
                      profile?.nationality ?? 'No registrada',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      'Miembro desde',
                      user?.createdAt.toString().split(' ')[0] ?? '',
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => _handleLogout(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cerrar Sesión',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await getIt<LoginViewModel>().logout();
                if (context.mounted) {
                  AppRoutes.goToLogin(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al cerrar sesión: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
