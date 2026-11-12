import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../services/db.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Орлого / зарлагын гүйлгээ нэмэх ("Add Expense" дэлгэц).
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  static const _other = 'Бусад';
  static const _expenseNames = [
    'Netflix',
    'Youtube',
    'Spotify',
    'Electricity',
    'House Rent',
    'Хоол хүнс',
    'Шилжүүлэг',
    _other,
  ];
  static const _incomeNames = ['Цалин', 'Upwork', 'Paypal', 'Шилжүүлэг', _other];

  bool _isIncome = false;
  String _name = _expenseNames.first;
  DateTime _date = DateTime.now();
  bool _saving = false;
  final _amount = TextEditingController();
  final _custom = TextEditingController();

  List<String> get _names => _isIncome ? _incomeNames : _expenseNames;

  @override
  void dispose() {
    _amount.dispose();
    _custom.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.trim().replaceAll(',', '.'));
    final title = _name == _other ? _custom.text.trim() : _name;
    if (title.isEmpty) {
      showMessage(context, 'Гүйлгээний нэрээ оруулна уу.');
      return;
    }
    if (amount == null || amount <= 0) {
      showMessage(context, 'Үнийн дүнгээ зөв оруулна уу.');
      return;
    }
    final now = DateTime.now();
    final date = DateTime(
        _date.year, _date.month, _date.day, now.hour, now.minute, now.second);
    setState(() => _saving = true);
    try {
      await Db.addTransaction(
        title: title,
        amount: amount,
        isIncome: _isIncome,
        date: date,
      );
      if (!mounted) return;
      showMessage(context,
          _isIncome ? 'Орлого хадгалагдлаа.' : 'Зарлага хадгалагдлаа.');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      showMessage(context, 'Алдаа гарлаа: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                letterSpacing: 0.6,
                color: AppColors.grey,
                fontWeight: FontWeight.w600)),
      );

  BoxDecoration get _box => BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDDDDD)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const HeaderBackground(height: 287),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.chevron_left,
                            color: Colors.white, size: 30),
                      ),
                      const Expanded(
                        child: Text('Төлбөр нэмэх',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 48, child: HeaderMoreButton()),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 30,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SegmentTabs(
                            labels: const ['Зарлага', 'Орлого'],
                            index: _isIncome ? 1 : 0,
                            onChanged: (i) => setState(() {
                              _isIncome = i == 1;
                              _name = _names.first;
                            }),
                          ),
                          _label('ГҮЙЛГЭЭНИЙ НЭР'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: _box,
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _name,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down),
                                items: [
                                  for (final n in _names)
                                    DropdownMenuItem(
                                      value: n,
                                      child: Row(
                                        children: [
                                          BrandLogo(n, size: 34, circle: true),
                                          const SizedBox(width: 10),
                                          Text(n,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: AppColors.grey,
                                                  fontWeight:
                                                      FontWeight.w500)),
                                        ],
                                      ),
                                    ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _name = v ?? _name),
                              ),
                            ),
                          ),
                          if (_name == _other) ...[
                            const SizedBox(height: 10),
                            TextField(
                              controller: _custom,
                              decoration: InputDecoration(
                                hintText: 'Гүйлгээний нэр',
                                isDense: true,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                          _label('ҮНИЙН ДҮН'),
                          TextField(
                            controller: _amount,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.,]')),
                            ],
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              prefixText: '\$ ',
                              prefixStyle: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600),
                              hintText: '0.00',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 15),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: AppColors.primary, width: 1.2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: AppColors.primary, width: 1.6),
                              ),
                            ),
                          ),
                          _label('ОГНОО'),
                          GestureDetector(
                            onTap: _pickDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              decoration: _box,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      DateFormat('EEE, d MMM yyyy')
                                          .format(_date),
                                      style: const TextStyle(
                                          color: AppColors.grey,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  const Icon(Icons.calendar_month,
                                      size: 20, color: AppColors.grey),
                                ],
                              ),
                            ),
                          ),
                          _label('ТӨЛБӨР'),
                          GestureDetector(
                            onTap: _saving ? null : _save,
                            child: CustomPaint(
                              painter: const DashedBorderPainter(
                                  color: Color(0xFFBBBBBB)),
                              child: Container(
                                height: 50,
                                alignment: Alignment.center,
                                color: Colors.transparent,
                                child: _saving
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2.5),
                                      )
                                    : const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.add_circle,
                                              color: AppColors.grey, size: 22),
                                          SizedBox(width: 8),
                                          Text('Төлбөр нэмэх',
                                              style: TextStyle(
                                                  color: AppColors.grey,
                                                  fontWeight:
                                                      FontWeight.w500)),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
