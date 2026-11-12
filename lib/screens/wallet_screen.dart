import 'package:flutter/material.dart';

import '../models.dart';
import '../services/db.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
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
              Center(
                child: AnimatedMoney(totals.balance,
                    style: const TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w700)),
              ),
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
        final addButton = Padding(
          padding: const EdgeInsets.only(top: 14),
          child: TextButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const _AddBillDialog(),
            ),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Төлбөр нэмэх'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        );
        if (bills.isEmpty) {
          return Column(
            children: [
              const EmptyState('Хүлээгдэж буй төлбөр алга.',
                  icon: Icons.check_circle_outline),
              addButton,
            ],
          );
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
            addButton,
          ],
        );
      },
    );
  }
}

/// Шинэ хүлээгдэж буй төлбөр (bill) нэмэх цонх.
class _AddBillDialog extends StatefulWidget {
  const _AddBillDialog();

  @override
  State<_AddBillDialog> createState() => _AddBillDialogState();
}

class _AddBillDialogState extends State<_AddBillDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  DateTime _due = DateTime.now().add(const Duration(days: 7));
  bool _saving = false;

  /// Үйлчилгээний хураамжийн хувь (үнийн 2%).
  static const _feeRate = 0.02;

  @override
  void initState() {
    super.initState();
    _price.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  double? _parse(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

  /// Хураамжийг үнээс автоматаар бодно (центээр бүхэлчилнэ).
  double get _fee {
    final p = _parse(_price.text);
    if (p == null || p <= 0) return 0;
    return (p * _feeRate * 100).round() / 100;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _due = picked);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await Db.addBill(
        name: _name.text.trim(),
        price: _parse(_price.text)!,
        fee: _fee,
        dueDate: _due,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
          const SnackBar(content: Text('Төлбөр нэмэгдлээ.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showMessage(context, 'Алдаа гарлаа: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const number = TextInputType.numberWithOptions(decimal: true);
    return AlertDialog(
      title: const Text('Төлбөр нэмэх'),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Нэр',
                  hintText: 'Netflix, House Rent ...',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Нэрээ оруулна уу'
                    : null,
              ),
              TextFormField(
                controller: _price,
                keyboardType: number,
                decoration: const InputDecoration(
                    labelText: 'Үнэ', prefixText: '\$ '),
                validator: (v) {
                  final p = _parse(v ?? '');
                  return (p == null || p <= 0) ? 'Үнээ зөв оруулна уу' : null;
                },
              ),
              const SizedBox(height: 14),
              AmountRow('Хураамж (2%)', money(_fee)),
              AmountRow('Нийт', money((_parse(_price.text) ?? 0) + _fee),
                  bold: true),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Төлөх огноо',
                    suffixIcon: Icon(Icons.calendar_month),
                  ),
                  child: Text(shortDate(_due)),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Болих'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: Text(_saving ? 'Хадгалж байна...' : 'Хадгалах'),
        ),
      ],
    );
  }
}
