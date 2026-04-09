import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/app_constants.dart';
import '/core/di/setup_dependencies.dart';
import '/core/routes/app_routes.dart';
import '/features/auth/presentation/viewmodels/login_viewmodel.dart';
import '/features/business/presentation/viewmodels/dashboard_viewmodel.dart';
import '/l10n/app_localizations.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const _darkBlue = Color(0xFF001F3F);
  static const _primaryGreen = Color(0xFF00DF5F);
  static const _bgGrey = Color(0xFFF3F3F4);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    // Leer el email directamente de Supabase Auth (siempre disponible si hay sesion)
    final supabaseUser = Supabase.instance.client.auth.currentUser;
    final email = supabaseUser?.email ?? '';
    final metadata = supabaseUser?.userMetadata ?? {};
    final googleName = metadata['full_name'] as String? ??
        metadata['name'] as String? ??
        '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l.profile, style: const TextStyle(fontWeight: FontWeight.w800, color: _darkBlue)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: _darkBlue),
            onPressed: () async {
              final result = await Navigator.pushNamed(context, AppConstants.editProfileRoute);
              if (result == true) {
                // El perfil ya se recargo en EditProfilePage
              }
            },
          ),
        ],
      ),
      body: Consumer<DashboardViewModel>(
        builder: (context, dashVM, _) {
          final profile = dashVM.profile;

          // Priorizar: profile.fullName > google metadata > email
          final displayName = (profile?.fullName.isNotEmpty == true)
              ? profile!.fullName
              : googleName.isNotEmpty
                  ? googleName
                  : email.split('@').first;

          final initials = _getInitials(displayName.isNotEmpty ? displayName : email);

          final avatarUrl = profile?.avatarUrl ??
              metadata['avatar_url'] as String? ??
              metadata['picture'] as String?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // ─── Avatar ───
                CircleAvatar(
                  radius: 48,
                  backgroundColor: _primaryGreen.withValues(alpha: 0.15),
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Text(
                          initials,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _primaryGreen),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  displayName.isNotEmpty ? displayName : 'Usuario',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _darkBlue),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(fontSize: 14, color: _darkBlue.withValues(alpha: 0.45), fontWeight: FontWeight.w500),
                ),
                if (profile?.role != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _primaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      profile!.role == 'microempresario' ? l.vendor : profile.role,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _primaryGreen),
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                _buildInfoTile(Icons.person_outline, l.nameProp, displayName.isNotEmpty ? displayName : l.notRegistered),
                _buildInfoTile(Icons.email_outlined, l.emailProp, email.isNotEmpty ? email : l.notRegistered),
                _buildInfoTile(Icons.phone_outlined, l.phoneProp, profile?.phone ?? l.notRegistered),
                _buildInfoTile(Icons.flag_outlined, l.nationalityProp, profile?.nationality ?? l.notRegisteredF),
                _buildInfoTile(
                  Icons.calendar_today_outlined,
                  l.memberSince,
                  profile?.createdAt != null ? profile!.createdAt.toString().split(' ')[0] : '-',
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleLogout(context, l),
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: Text(l.logout, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
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
      decoration: BoxDecoration(color: _bgGrey, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, size: 22, color: _darkBlue.withValues(alpha: 0.4)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _darkBlue.withValues(alpha: 0.4), letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _darkBlue)),
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
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  void _handleLogout(BuildContext context, AppLocalizations l) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.logout),
        content: Text(l.logoutConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await getIt<LoginViewModel>().logout();
                if (context.mounted) AppRoutes.goToLogin(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text(l.logout, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
