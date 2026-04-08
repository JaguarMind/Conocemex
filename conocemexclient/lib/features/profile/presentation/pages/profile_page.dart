import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/core/di/setup_dependencies.dart';
import '/core/routes/app_routes.dart';
import '/features/auth/presentation/viewmodels/login_viewmodel.dart';
import '/features/business/presentation/viewmodels/dashboard_viewmodel.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const _darkBlue = Color(0xFF001F3F);
  static const _primaryGreen = Color(0xFF00DF5F);
  static const _bgGrey = Color(0xFFF3F3F4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Perfil',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: _darkBlue,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer2<DashboardViewModel, LoginViewModel>(
        builder: (context, dashVM, loginVM, _) {
          final profile = dashVM.profile;
          final user = loginVM.auth?.user;
          final displayName = profile?.fullName.isNotEmpty == true
              ? profile!.fullName
              : '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();
          final email = user?.email ?? '';
          final initials = _getInitials(displayName.isNotEmpty ? displayName : email);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // ─── Avatar ───
                CircleAvatar(
                  radius: 48,
                  backgroundColor: _primaryGreen.withValues(alpha: 0.15),
                  backgroundImage: profile?.avatarUrl != null
                      ? NetworkImage(profile!.avatarUrl!)
                      : null,
                  child: profile?.avatarUrl == null
                      ? Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: _primaryGreen,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  displayName.isNotEmpty ? displayName : 'Usuario',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _darkBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 14,
                    color: _darkBlue.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (profile?.role != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      profile!.role == 'microempresario'
                          ? 'Vendedor'
                          : profile.role,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _primaryGreen,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                // ─── Info Cards ───
                _buildInfoTile(
                  Icons.person_outline,
                  'Nombre',
                  displayName.isNotEmpty ? displayName : 'No registrado',
                ),
                _buildInfoTile(
                  Icons.email_outlined,
                  'Correo',
                  email.isNotEmpty ? email : 'No registrado',
                ),
                _buildInfoTile(
                  Icons.phone_outlined,
                  'Telefono',
                  profile?.phone ?? 'No registrado',
                ),
                _buildInfoTile(
                  Icons.flag_outlined,
                  'Nacionalidad',
                  profile?.nationality ?? 'No registrada',
                ),
                _buildInfoTile(
                  Icons.calendar_today_outlined,
                  'Miembro desde',
                  profile?.createdAt != null
                      ? profile!.createdAt.toString().split(' ')[0]
                      : '-',
                ),

                const SizedBox(height: 32),

                // ─── Logout ───
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleLogout(context),
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text(
                      'Cerrar Sesion',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: _darkBlue.withValues(alpha: 0.4)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _darkBlue.withValues(alpha: 0.4),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _darkBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesion'),
        content: const Text('Estas seguro de que deseas cerrar sesion?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await getIt<LoginViewModel>().logout();
                if (context.mounted) AppRoutes.goToLogin(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Cerrar sesion',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
