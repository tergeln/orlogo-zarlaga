import 'package:flutter/material.dart';

import '../models.dart';
import '../services/auth_service.dart';
import '../services/db.dart';
import '../theme.dart';
import '../widgets/common.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Өглөөний мэнд?';
    if (h < 18) return 'Өдрийн мэнд?';
    return 'Оройн мэнд?';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TxModel>>(
      stream: Db.transactions(),
      builder: (context, snap) {
        final list = snap.data ?? const <TxModel>[];
        final totals = Totals.of(list);
        return Stack(
          children: [
            const HeaderBackground(height: 287),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_greeting,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(
                                AuthService.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const BellButton(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _BalanceCard(totals),
                  ),
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text('Гүйлгээний Түүх',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600)),
                        ),
                        GestureDetector(
                          onTap: () => tabIndex.value = 2,
                          child: const Text('Бүгдийг харах',
                              style: TextStyle(
                                  fontSize: 14, color: AppColors.grey)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: snap.hasError
                        ? EmptyState('Өгөгдөл уншихад алдаа гарлаа.\n${snap.error}',
                            icon: Icons.error_outline)
                        : !snap.hasData
                            ? const Center(child: CircularProgressIndicator())
                            : list.isEmpty
                                ? const SingleChildScrollView(
                                    child: EmptyState(
                                        'Одоогоор гүйлгээ алга.\n"+" товчоор орлого, зарлагаа нэмээрэй.'),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                        22, 8, 22, 40),
                                    itemCount: list.length,
                                    itemBuilder: (_, i) =>
                                        TransactionTile(list[i]),
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

class _BalanceCard extends StatelessWidget {
  final Totals totals;
  const _BalanceCard(this.totals);

  Widget _stat(IconData icon, String label, double value, bool right) {
    return Column(
      crossAxisAlignment:
          right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 6),
            Text(label,
                style:
                    const TextStyle(color: Color(0xFFD0E5E4), fontSize: 16)),
          ],
        ),
        const SizedBox(height: 6),
        Text(money(value),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5C58).withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('Нийт үлдэгдэл',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 18),
              Spacer(),
              Icon(Icons.more_horiz, color: Colors.white),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(money(totals.balance),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stat(Icons.arrow_downward, 'Орлого', totals.income, false),
              _stat(Icons.arrow_upward, 'Зарлага', totals.expense, true),
            ],
          ),
        ],
      ),
    );
  }
}
