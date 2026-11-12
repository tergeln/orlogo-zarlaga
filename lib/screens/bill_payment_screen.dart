import 'package:flutter/material.dart';

import '../models.dart';
import '../services/db.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'bill_details_screen.dart';
import 'receipt_screen.dart';

/// Төлбөр баталгаажуулах ("Bill Payment" 1-р дэлгэц).
class BillPaymentScreen extends StatefulWidget {
  final Bill bill;
  final String method;
  const BillPaymentScreen({super.key, required this.bill, required this.method});

  @override
  State<BillPaymentScreen> createState() => _BillPaymentScreenState();
}

class _BillPaymentScreenState extends State<BillPaymentScreen> {
  bool _loading = false;

  Future<void> _confirm() async {
    setState(() => _loading = true);
    try {
      if (widget.method == payByWallet) {
        final totals = await Db.totals();
        if (totals.balance < widget.bill.total) {
          if (!mounted) return;
          showMessage(context,
              'Түрийвчний үлдэгдэл хүрэлцэхгүй байна. Түрийвчээ цэнэглэнэ үү.');
          return;
        }
      }
      final receipt = await Db.payBill(widget.bill, widget.method);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ReceiptScreen(receipt: receipt)),
      );
    } catch (e) {
      if (!mounted) return;
      showMessage(context, 'Алдаа гарлаа: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;
    return PageScaffold(
      title: 'Bill Payment',
      action: const Icon(Icons.more_horiz, color: Colors.white),
      navIndex: 2,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 34, 22, 24),
        children: [
          Center(child: BrandLogo(bill.name, size: 72, circle: true)),
          const SizedBox(height: 18),
          Text.rich(
            TextSpan(
              style: const TextStyle(
                  fontSize: 18, height: 1.4, color: AppColors.text),
              children: [
                const TextSpan(text: 'Та '),
                TextSpan(
                  text: bill.name,
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
                TextSpan(text: '-ийн төлбөрийг\n${widget.method}-аар төлөх гэж байна'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          AmountRow('Үнэ', money(bill.price)),
          AmountRow('Хураамж', money(bill.fee)),
          const Divider(height: 22),
          AmountRow('Нийт', money(bill.total), bold: true),
          const SizedBox(height: 90),
          PrimaryButton(
            label: 'Баталгаажуулах',
            loading: _loading,
            onPressed: _confirm,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
