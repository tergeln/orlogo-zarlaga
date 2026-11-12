import 'dart:math';

import 'package:flutter/material.dart';

import '../models.dart';
import '../services/db.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Орлого, зарлагын тойм (Figma-д тусдаа дэлгэц байхгүй, доод цэсний 2-р таб).
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  Widget _bar(String label, double value, double top, Color color) {
    final double ratio =
        top <= 0 ? 0.0 : (value / top).clamp(0.0, 1.0).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
              ),
              Text(money(value),
                  style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 12,
              color: color,
              backgroundColor: AppColors.segment,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Статистик',
      action: const BellButton(),
      onBack: () => tabIndex.value = 0,
      child: StreamBuilder<List<TxModel>>(
        stream: Db.transactions(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data!;
          final totals = Totals.of(list);
          final top = max(totals.income, totals.expense);
          final byTitle = <String, double>{};
          for (final t in list.where((t) => !t.isIncome)) {
            byTitle[t.title] = (byTitle[t.title] ?? 0) + t.amount;
          }
          final spending = byTitle.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          return ListView(
            padding: const EdgeInsets.fromLTRB(22, 30, 22, 60),
            children: [
              _bar('Орлого', totals.income, top, AppColors.income),
              _bar('Зарлага', totals.expense, top, AppColors.expense),
              const SizedBox(height: 22),
              const Text('Хамгийн их зарлага',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (spending.isEmpty)
                const EmptyState('Зарлагын гүйлгээ алга.')
              else
                for (final e in spending)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        BrandLogo(e.key),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(e.key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500)),
                        ),
                        Text('- ${money(e.value)}',
                            style: const TextStyle(
                                color: AppColors.expense,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
