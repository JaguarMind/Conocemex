import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '/core/di/setup_dependencies.dart';
import '/core/services/community_service.dart';
import '/features/auth/presentation/pages/chat_page.dart';
import '/l10n/app_localizations.dart';

class CommunitiesPage extends StatefulWidget {
  const CommunitiesPage({super.key});

  @override
  State<CommunitiesPage> createState() => _CommunitiesPageState();
}

class _CommunitiesPageState extends State<CommunitiesPage> {
  static const _darkBlue = Color(0xFF001F3F);
  static const _primaryGreen = Color(0xFF00DF5F);
  static const _bgGrey = Color(0xFFF3F3F4);

  late final CommunityService _service;
  List<Map<String, dynamic>> _myCommunities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = getIt<CommunityService>();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      _myCommunities = await _service.getMyCommunities();
    } catch (e) {
      debugPrint('[Communities] Error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _openChat(Map<String, dynamic> community) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          communityId: community['id'] as String,
          communityName: community['name'] as String,
        ),
      ),
    ).then((_) => _loadData());
  }

  // ─── Crear comunidad ───
  void _showCreateSheet() {
    final l = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(l.createCommunity, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _darkBlue)),
            const SizedBox(height: 16),
            _buildSheetField(nameCtrl, l.communityName),
            const SizedBox(height: 12),
            _buildSheetField(descCtrl, l.communityDescription, maxLines: 3),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  Navigator.pop(ctx);
                  try {
                    final created = await _service.createCommunity(name: name, description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim());
                    await _loadData();
                    if (mounted) {
                      // Mostrar codigo de invitacion
                      _showInviteCodeDialog(created);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen, foregroundColor: _darkBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(l.createCommunity, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Mostrar codigo de invitacion despues de crear ───
  void _showInviteCodeDialog(Map<String, dynamic> community) {
    final l = AppLocalizations.of(context)!;
    final code = _service.getInviteCode(community);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: _primaryGreen, size: 28),
            const SizedBox(width: 8),
            Expanded(child: Text(l.communityCreated, style: const TextStyle(fontWeight: FontWeight.w800, color: _darkBlue, fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.shareInviteCode, style: TextStyle(color: _darkBlue.withValues(alpha: 0.6), fontSize: 14)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.codeCopied), backgroundColor: _primaryGreen),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _bgGrey,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _primaryGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(code, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _darkBlue, letterSpacing: 2)),
                    const SizedBox(width: 12),
                    Icon(Icons.copy, size: 18, color: _darkBlue.withValues(alpha: 0.4)),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.share, size: 18),
            onPressed: () {
              Navigator.pop(ctx);
              final name = community['name'] as String? ?? '';
              SharePlus.instance.share(
                ShareParams(text: 'Unete a "$name" en CONOCEMEX con el codigo: $code'),
              );
            },
            label: Text(l.share, style: const TextStyle(fontWeight: FontWeight.w700, color: _primaryGreen)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: const TextStyle(fontWeight: FontWeight.w700, color: _primaryGreen)),
          ),
        ],
      ),
    );
  }

  // ─── Unirse por codigo ───
  void _showJoinByCodeSheet() {
    final l = AppLocalizations.of(context)!;
    final codeCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(l.joinWithCode, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _darkBlue)),
            const SizedBox(height: 8),
            Text(l.enterInviteCode, style: TextStyle(fontSize: 14, color: _darkBlue.withValues(alpha: 0.5))),
            const SizedBox(height: 16),
            _buildSheetField(codeCtrl, l.inviteCode),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final code = codeCtrl.text.trim();
                  if (code.isEmpty) return;
                  Navigator.pop(ctx);
                  try {
                    final name = await _service.joinByInviteCode(code);
                    await _loadData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${l.joinedCommunity}: $name'), backgroundColor: Colors.green),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen, foregroundColor: _darkBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(l.joinCommunity, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Ver codigo de invitacion de una comunidad ───
  void _showCommunityOptions(Map<String, dynamic> community) {
    final l = AppLocalizations.of(context)!;
    final code = _service.getInviteCode(community);
    final isAdmin = community['my_role'] == 'admin';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              Text(community['name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w800, color: _darkBlue, fontSize: 16)),
              const SizedBox(height: 8),
              // Codigo de invitacion
              ListTile(
                leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: _primaryGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.link, color: _primaryGreen)),
                title: Text(l.inviteCode, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(code, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
                trailing: IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.codeCopied), backgroundColor: _primaryGreen),
                    );
                  },
                ),
              ),
              // Compartir
              ListTile(
                leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: _primaryGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.share, color: _primaryGreen)),
                title: Text(l.share, style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  final name = community['name'] as String? ?? '';
                  SharePlus.instance.share(
                    ShareParams(text: 'Unete a "$name" en CONOCEMEX con el codigo: $code'),
                  );
                },
              ),
              // Salir de comunidad
              if (!isAdmin)
                ListTile(
                  leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.exit_to_app, color: Colors.red)),
                  title: Text(l.leaveCommunity, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _service.leaveCommunity(community['id'] as String);
                    await _loadData();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, automaticallyImplyLeading: false,
        title: Text(l.chat, style: const TextStyle(fontWeight: FontWeight.w800, color: _darkBlue)),
        centerTitle: true,
        actions: [
          // Boton solicitudes (placeholder)
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.mark_email_unread_outlined, color: _darkBlue.withValues(alpha: 0.5)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.requestsComingSoon), backgroundColor: Colors.orange),
                  );
                },
              ),
              // Badge (placeholder, se activara cuando haya direct_chats)
              // Positioned(right: 8, top: 8, child: badge),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primaryGreen))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  // ─── Seccion: Chats Directos (placeholder) ───
                  _buildSectionHeader(l.directChats, Icons.chat_outlined),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _bgGrey,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 32, color: _darkBlue.withValues(alpha: 0.2)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.comingSoon, style: TextStyle(fontWeight: FontWeight.w700, color: _darkBlue.withValues(alpha: 0.5))),
                              const SizedBox(height: 2),
                              Text(l.directChatsSubtitle, style: TextStyle(fontSize: 12, color: _darkBlue.withValues(alpha: 0.35))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── Seccion: Comunidades ───
                  _buildSectionHeader(l.myCommunities, Icons.groups),
                  const SizedBox(height: 4),

                  // Boton unirse por codigo
                  _buildJoinByCodeButton(l),
                  const SizedBox(height: 8),

                  if (_myCommunities.isEmpty)
                    _buildEmptyCommunities(l)
                  else
                    ..._myCommunities.map((c) => _buildCommunityCard(c)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSheet,
        backgroundColor: _primaryGreen,
        foregroundColor: _darkBlue,
        child: const Icon(Icons.group_add),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _darkBlue.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _darkBlue.withValues(alpha: 0.5), letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildJoinByCodeButton(AppLocalizations l) {
    return GestureDetector(
      onTap: _showJoinByCodeSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _primaryGreen.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _primaryGreen.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.qr_code, size: 20, color: _primaryGreen),
            const SizedBox(width: 10),
            Text(l.joinWithCode, style: const TextStyle(fontWeight: FontWeight.w700, color: _darkBlue, fontSize: 14)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 14, color: _darkBlue.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCommunities(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.groups_outlined, size: 48, color: _darkBlue.withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          Text(l.noCommunities, style: TextStyle(fontWeight: FontWeight.w700, color: _darkBlue.withValues(alpha: 0.35))),
          const SizedBox(height: 4),
          Text(l.discoverSubtitle, style: TextStyle(fontSize: 13, color: _darkBlue.withValues(alpha: 0.25))),
        ],
      ),
    );
  }

  Widget _buildCommunityCard(Map<String, dynamic> community) {
    final l = AppLocalizations.of(context)!;
    final name = community['name'] as String? ?? '';
    final desc = community['description'] as String? ?? '';
    final memberCount = community['member_count'] as int? ?? 0;
    final isAdmin = community['my_role'] == 'admin';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: _darkBlue.withValues(alpha: 0.06)),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openChat(community),
        onLongPress: () => _showCommunityOptions(community),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: _primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.groups, color: _primaryGreen, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, color: _darkBlue, fontSize: 15))),
                        if (isAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: _primaryGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                            child: const Text('Admin', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _primaryGreen)),
                          ),
                      ],
                    ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: _darkBlue.withValues(alpha: 0.4))),
                    ],
                    const SizedBox(height: 3),
                    Text('$memberCount ${l.members}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _darkBlue.withValues(alpha: 0.3))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: _darkBlue.withValues(alpha: 0.2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetField(TextEditingController ctrl, String label, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(fontWeight: FontWeight.w600, color: _darkBlue),
      decoration: InputDecoration(
        labelText: label,
        filled: true, fillColor: _bgGrey,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primaryGreen, width: 2)),
      ),
    );
  }
}
