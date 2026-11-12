import 'package:flutter/material.dart';

import '../models.dart';
import '../services/db.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'bill_details_screen.dart';
import 'connect_wallet_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  int _tab = 0;

  Widget _circleAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 1.2),
            ),
            child: Icon(icon, color: AppColors.primary, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Түрийвч',
      action: const BellButton(),
      onBack: () => tabIndex.value = 0,
      child: StreamBuilder<List<TxModel>>(
        stream: Db.transactions(),
        builder: (context, txSnap) {
          final txs = txSnap.data ?? const <TxModel>[];
          final totals = Totals.of(txs);
          return ListView(
            padding: const EdgeInsets.fromLTRB(22, 34, 22, 24),
            children: [
              const Text('Нийт үлдэгдэл',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppColors.grey)),
              const SizedBox(height: 8),
              Text(money(totals.balance),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 30, fontWeight: FontWeight.w700)),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _circleAction(
                    Icons.add,
                    'Нэмэх',
                    () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ConnectWalletScreen())),
                  ),
                  const SizedBox(width: 56),
                  _circleAction(Icons.qr_code_2, 'Төлбөр',
                      () => setState(() => _tab = 1)),
                ],
              ),
              const SizedBox(height: 30),
              SegmentTabs(
                labels: const ['Гүйлгээнүүд', 'Хүлээгдэж буй гүйлгээ'],
                index: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
              const SizedBox(height: 14),
              if (_tab == 0) ...[
                if (txSnap.hasError)
                  EmptyState('Алдаа: ${txSnap.error}',
                      icon: Icons.error_outline)
                else if (!txSnap.hasData)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (txs.isEmpty)
                  const EmptyState('Гүйлгээ алга байна.')
                else
                  for (final t in txs) TransactionTile(t),
              ] else
                const _PendingBills(),
            ],
          );
        },
      ),
    );
  }
}

class _PendingBills extends StatelessWidget {
  const _PendingBills();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Bill>>(
      stream: Db.pendingBills(),
      builder: (context, snap) {
        if (snap.hasError) {
          return EmptyState('Алдаа: ${snap.error}', icon: Icons.error_outline);
        }
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final bills = snap.data!;
        if (bills.isEmpty) {
          return const EmptyState('Хүлээгдэж буй төлбөр алга.',
              icon: Icons.check_circle_outline);
        }
        return Column(
          children: [
            for (final b in bills)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    BrandLogo(b.name),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(shortDate(b.dueDate),
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.grey)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => BillDetailsScreen(bill: b)),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.pill,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Text('Төлөх',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
