import 'package:flutter/material.dart';

import '../models.dart';
import '../services/auth_service.dart';
import '../services/db.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'onboarding_screen.dart';
import 'receipt_screen.dart';

/// Профайл: хэрэглэгчийн мэдээлэл, хадгалагдсан баримтууд, гарах.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService.user?.email ?? '';
    return PageScaffold(
      title: 'Профайл',
      action: const BellButton(),
      onBack: () => tabIndex.value = 0,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 30, 22, 24),
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.tile,
            child: Icon(Icons.person, size: 44, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(AuthService.displayName,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(email,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.primary)),
          const SizedBox(height: 26),
          const Text('Миний баримтууд',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          StreamBuilder<List<Receipt>>(
            stream: Db.receipts(),
            builder: (context, snap) {
              if (snap.hasError) {
                return EmptyState('Алдаа: ${snap.error}',
                    icon: Icons.error_outline);
              }
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final receipts = snap.data!;
              if (receipts.isEmpty) {
                return const EmptyState(
                    'Төлбөр төлсний дараа баримт энд хадгалагдана.');
              }
              return Column(
                children: [
                  for (final r in receipts)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: BrandLogo(r.billName),
                      title: Text(r.billName,
                          style:
                              const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(shortDate(r.paidAt)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(money(r.total),
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 6),
                          const Icon(Icons.qr_code_2,
                              color: AppColors.primary),
                        ],
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => ReceiptScreen(receipt: r)),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          OutlinePillButton(label: 'Гарах', onPressed: () => _logout(context)),
        ],
      ),
    );
  }
}
