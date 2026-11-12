import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'bill_payment_screen.dart';

const payByCard = 'Дебит карт';
const payByWallet = 'Түрийвч';

/// Төлбөрийн дэлгэрэнгүй ("Bill Details" дэлгэц).
class BillDetailsScreen extends StatefulWidget {
  final Bill bill;
  const BillDetailsScreen({super.key, required this.bill});

  @override
  State<BillDetailsScreen> createState() => _BillDetailsScreenState();
}

class _BillDetailsScreenState extends State<BillDetailsScreen> {
  String _method = payByCard;

  Widget _methodTile(String method, IconData icon) {
    final selected = _method == method;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => setState(() => _method = method),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? AppColors.pill : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : const Color(0xFFF0F0F0),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon,
                    color: selected
                        ? AppColors.primary
                        : const Color(0xFF888888)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(method,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            selected ? AppColors.primary : AppColors.grey)),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? AppColors.primary : AppColors.lightGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;
    return PageScaffold(
      title: 'Bill Details',
      action: const Icon(Icons.more_horiz, color: Colors.white),
      navIndex: 2,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
        children: [
          Row(
            children: [
              BrandLogo(bill.name, size: 60),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bill.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(shortDate(bill.dueDate),
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          AmountRow('Үнэ', money(bill.price)),
          AmountRow('Хураамж', money(bill.fee)),
          const Divider(height: 22),
          AmountRow('Нийт', money(bill.total), bold: true),
          const SizedBox(height: 22),
          const Text('Төлбөрийн хэрэгслээ сонго',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          _methodTile(payByCard, Icons.credit_card),
          _methodTile(payByWallet, Icons.account_balance_wallet),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Төлөх',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BillPaymentScreen(bill: bill, method: _method),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
