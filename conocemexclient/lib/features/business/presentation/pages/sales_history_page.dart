import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/di/setup_dependencies.dart';
import '/features/business/presentation/viewmodels/dashboard_viewmodel.dart';
import '/l10n/app_localizations.dart';

class SalesHistoryPage extends StatefulWidget {
  const SalesHistoryPage({super.key});

  @override
  State<SalesHistoryPage> createState() => _SalesHistoryPageState();
}

class _SalesHistoryPageState extends State<SalesHistoryPage> {
  static const _darkBlue = Color(0xFF001F3F);
  static const _primaryGreen = Color(0xFF00DF5F);
  static const _bgGrey = Color(0xFFF3F3F4);

  String? _selectedBusinessId;
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = false;

  late final DashboardViewModel _dashVM;

  @override
  void initState() {
    super.initState();
    _dashVM = getIt<DashboardViewModel>();
    _dashVM.addListener(_onChanged);
  }

  @override
  void dispose() {
    _dashVM.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadTransactions(String businessId) async {
    setState(() { _loading = true; _selectedBusinessId = businessId; });

    try {
      final rows = await Supabase.instance.client
          .from('transactions')
          .select('id, amount_mxn, status, description, payment_method, created_at, mp_preference_id, payment_provider_id')
          .eq('business_id', businessId)
          .order('created_at', ascending: false)
          .limit(50);

      if (mounted) {
        setState(() {
          _transactions = List<Map<String, dynamic>>.from(rows);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(String? ts) {
    if (ts == null) return '';
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed': return _primaryGreen;
      case 'pending': return Colors.orange;
      case 'failed': return Colors.red;
      case 'refunded': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status, AppLocalizations l) {
    switch (status) {
      case 'completed': return l.saleCompleted;
      case 'pending': return l.salePending;
      case 'failed': return l.saleFailed;
      case 'refunded': return l.saleRefunded;
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final businesses = _dashVM.businesses;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, automaticallyImplyLeading: false,
        title: Text(l.sales, style: const TextStyle(fontWeight: FontWeight.w800, color: _darkBlue)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Selector de negocio
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: _bgGrey, borderRadius: BorderRadius.circular(14)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedBusinessId,
                hint: Row(children: [
                  Icon(Icons.store, size: 20, color: _darkBlue.withValues(alpha: 0.4)),
                  const SizedBox(width: 10),
                  Text(l.selectBusiness, style: TextStyle(color: _darkBlue.withValues(alpha: 0.4), fontWeight: FontWeight.w600)),
                ]),
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down, color: _darkBlue.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(14),
                items: businesses.map((biz) => DropdownMenuItem<String>(
                  value: biz.id,
                  child: Text(biz.name, style: const TextStyle(fontWeight: FontWeight.w700, color: _darkBlue, fontSize: 14)),
                )).toList(),
                onChanged: (id) {
                  if (id != null) _loadTransactions(id);
                },
              ),
            ),
          ),

          // Contenido
          Expanded(
            child: _selectedBusinessId == null
                ? _buildSelectPrompt(l)
                : _loading
                    ? const Center(child: CircularProgressIndicator(color: _primaryGreen))
                    : _transactions.isEmpty
                        ? _buildEmpty(l)
                        : _buildList(l),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectPrompt(AppLocalizations l) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.receipt_long, size: 56, color: _darkBlue.withValues(alpha: 0.15)),
        const SizedBox(height: 16),
        Text(l.selectBusinessSales, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _darkBlue.withValues(alpha: 0.4))),
      ]),
    );
  }

  Widget _buildEmpty(AppLocalizations l) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.receipt_long_outlined, size: 56, color: _darkBlue.withValues(alpha: 0.15)),
        const SizedBox(height: 16),
        Text(l.noSales, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _darkBlue.withValues(alpha: 0.4))),
      ]),
    );
  }

  Widget _buildList(AppLocalizations l) {
    return RefreshIndicator(
      onRefresh: () => _loadTransactions(_selectedBusinessId!),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: _transactions.length,
        itemBuilder: (_, i) => _buildTransactionCard(_transactions[i], l),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx, AppLocalizations l) {
    final amount = (tx['amount_mxn'] as num?)?.toDouble() ?? 0;
    final status = tx['status'] as String? ?? 'pending';
    final desc = tx['description'] as String? ?? '';
    final date = _formatDate(tx['created_at'] as String?);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: _darkBlue.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _statusColor(status).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                status == 'completed' ? Icons.check_circle : status == 'pending' ? Icons.schedule : Icons.error_outline,
                color: _statusColor(status), size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('\$${amount.toStringAsFixed(2)} MXN', style: const TextStyle(fontWeight: FontWeight.w800, color: _darkBlue, fontSize: 16)),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: _darkBlue.withValues(alpha: 0.5))),
                  ],
                  const SizedBox(height: 4),
                  Text(date, style: TextStyle(fontSize: 11, color: _darkBlue.withValues(alpha: 0.35))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(status).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusLabel(status, l),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor(status)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
