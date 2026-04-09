import 'package:flutter/material.dart';

import '/l10n/app_localizations.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  static const _darkBlue = Color(0xFF001F3F);
  static const _primaryGreen = Color(0xFF00DF5F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.orders,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: _darkBlue,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.receipt_long,
                size: 40,
                color: _primaryGreen,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.comingSoon,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.ordersSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _darkBlue.withValues(alpha: 0.45),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
