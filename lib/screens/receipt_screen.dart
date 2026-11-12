import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Амжилттай төлөгдсөн баримт + QR ("Bill Payment" 2-р дэлгэц).
class ReceiptScreen extends StatefulWidget {
  final Receipt receipt;
  const ReceiptScreen({super.key, required this.receipt});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  bool _expanded = true;

  Future<void> _copy(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    showMessage(context, message);
  }

  String get _receiptText {
    final r = widget.receipt;
    return [
      'Төлбөрийн баримт — ${r.billName}',
      'Гүйлгээний дугаар: ${r.number}',
      'Төлбөрийн хэрэгсэл: ${r.method}',
      'Огноо: ${shortDate(r.paidAt)} ${DateFormat('hh:mm a').format(r.paidAt)}',
      'Үнэ: ${money(r.price)}',
      'Хураамж: ${money(r.fee)}',
      'Нийт: ${money(r.total)}',
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.receipt;
    return PageScaffold(
      title: 'Bill Payment',
      action: const HeaderMoreButton(),
      navIndex: 2,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
        children: [
          const Text('Амжилттай Төлөгдлөө',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(r.billName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.grey)),
          const SizedBox(height: 10),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (_, t, child) =>
                  Transform.scale(scale: t, child: child),
              child: const CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.tile,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.check, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Гүйлгээний дэлгэрэнгүй',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600)),
                ),
                Icon(_expanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down),
              ],
            ),
          ),
          const SizedBox(height: 6),
          if (_expanded) ...[
            AmountRow('Төлбөрийн хэрэгсэл', r.method),
            const AmountRow('Төлөв', 'Хийгдсэн',
                valueColor: AppColors.primary),
            AmountRow('Цаг', DateFormat('hh:mm a').format(r.paidAt)),
            AmountRow('Огноо', shortDate(r.paidAt)),
            AmountRow(
              'Гүйлгээний дугаар',
              r.number,
              trailing: GestureDetector(
                onTap: () => _copy(r.number, 'Гүйлгээний дугаар хуулагдлаа.'),
                child: const Icon(Icons.copy,
                    size: 16, color: AppColors.primary),
              ),
            ),
            const Divider(height: 18),
          ],
          AmountRow('Үнэ', money(r.price)),
          AmountRow('Хураамж', '- ${money(r.fee)}'),
          const Divider(height: 18),
          AmountRow('Нийт', money(r.total), bold: true),
          const SizedBox(height: 10),
          Center(
            child: QrImageView(
              data: r.qrData,
              version: QrVersions.auto,
              size: 190,
              padding: const EdgeInsets.all(12),
              errorCorrectionLevel: QrErrorCorrectLevel.M,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 44),
            child: OutlinePillButton(
              label: 'Share Receipt',
              onPressed: () => _copy(_receiptText, 'Баримт хуулагдлаа.'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
