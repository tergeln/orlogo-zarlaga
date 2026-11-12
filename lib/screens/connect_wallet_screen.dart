import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/db.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Түрийвч цэнэглэх / түрийвчтэй холбох ("Connect Wallet" 2 дэлгэц).
class ConnectWalletScreen extends StatefulWidget {
  const ConnectWalletScreen({super.key});

  @override
  State<ConnectWalletScreen> createState() => _ConnectWalletScreenState();
}

class _ConnectWalletScreenState extends State<ConnectWalletScreen> {
  int _tab = 0;
  int _account = 0;
  bool _loading = false;

  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _number = TextEditingController();
  final _cvc = TextEditingController();
  final _expiry = TextEditingController();
  final _value = TextEditingController();

  static const _accounts = [
    (Icons.account_balance, 'Bank Link', 'Connect your bank\naccount to deposit & fund'),
    (Icons.monetization_on, 'Microdeposits', 'Connect bank in 5-7 days'),
    (Icons.paypal, 'Paypal', 'Connect you paypal account'),
  ];

  @override
  void initState() {
    super.initState();
    _name.addListener(_refresh);
    _number.addListener(_refresh);
    _expiry.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    _cvc.dispose();
    _expiry.dispose();
    _value.dispose();
    super.dispose();
  }

  double? _parse(String s) {
    final v = double.tryParse(s.trim().replaceAll(',', '.'));
    return (v == null || v <= 0) ? null : v;
  }

  Future<void> _topUp(double amount, String source) async {
    setState(() => _loading = true);
    try {
      await Db.topUp(amount, source);
      if (!mounted) return;
      showMessage(context, 'Түрийвч ${money(amount)}-оор цэнэглэгдлээ.');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      showMessage(context, 'Алдаа гарлаа: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitCard() async {
    if (!_form.currentState!.validate()) return;
    final digits = _number.text.replaceAll(' ', '');
    final last4 = digits.substring(digits.length - 4);
    try {
      await Db.saveCard(
        holder: _name.text.trim(),
        last4: last4,
        expiry: _expiry.text.trim(),
      );
    } catch (_) {
      // Карт хадгалах амжилтгүй болсон ч цэнэглэлтийг үргэлжлүүлнэ.
    }
    await _topUp(_parse(_value.text)!, 'Карт •••• $last4');
  }

  Future<void> _submitAccount() async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${_accounts[_account].$2}-ээр цэнэглэх'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            prefixText: '\$ ',
            hintText: 'Цэнэглэх дүн',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Болих'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(_parse(controller.text)),
            child: const Text('Цэнэглэх'),
          ),
        ],
      ),
    );
    if (amount == null) return;
    await _topUp(amount, _accounts[_account].$2);
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: _tab == 0 ? 'Түрийвч цэнэглэх' : 'Түрийвчтэй холбох',
      action: const BellButton(),
      navIndex: 2,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
        children: [
          SegmentTabs(
            labels: const ['Картууд', 'Аккаунт'],
            index: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: 22),
          if (_tab == 0) ..._cardTab() else ..._accountTab(),
        ],
      ),
    );
  }

  // ---------------- Картууд ----------------

  List<Widget> _cardTab() {
    return [
      _CardPreview(
        holder: _name.text.trim().isEmpty ? 'IRVAN MOSES' : _name.text.trim(),
        number: _number.text.trim().isEmpty
            ? '6219 8610 2888 8075'
            : _number.text.trim(),
        expiry: _expiry.text.trim().isEmpty ? '22/01' : _expiry.text.trim(),
      ),
      const SizedBox(height: 20),
      const Text('Картны мэдээллээ нэмэх',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      const Text('Энд холбох карт нь зөвхөн таны нэр дээр байх ёстой.',
          style: TextStyle(fontSize: 13, color: AppColors.grey)),
      const SizedBox(height: 16),
      Form(
        key: _form,
        child: Column(
          children: [
            _field(
              controller: _name,
              label: 'КАРТ ДЭЭРХ НЭР',
              capitalization: TextCapitalization.characters,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Нэрээ оруулна уу' : null,
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _field(
                    controller: _number,
                    label: 'КАРТЫН ДУГААР',
                    keyboard: TextInputType.number,
                    formatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                      _GroupFormatter(),
                    ],
                    validator: (v) =>
                        (v ?? '').replaceAll(' ', '').length < 12
                            ? 'Дугаар дутуу'
                            : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _field(
                    controller: _cvc,
                    label: 'CVC',
                    keyboard: TextInputType.number,
                    obscure: true,
                    formatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: (v) =>
                        (v ?? '').length < 3 ? 'CVC буруу' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _field(
                    controller: _expiry,
                    label: 'ДУУСАХ ХУГАЦАА YYYY/MM',
                    keyboard: TextInputType.datetime,
                    formatters: [LengthLimitingTextInputFormatter(7)],
                    validator: (v) => (v == null || v.trim().length < 4)
                        ? 'Хугацаа оруулна уу'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _field(
                    controller: _value,
                    label: 'Value \$',
                    keyboard:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) =>
                        _parse(v ?? '') == null ? 'Дүн оруулна уу' : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      OutlinePillButton(
        label: 'ИЛГЭЭХ',
        loading: _loading,
        onPressed: _submitCard,
      ),
    ];
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboard,
    bool obscure = false,
    TextCapitalization capitalization = TextCapitalization.none,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c, width: w),
        );
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      textCapitalization: capitalization,
      inputFormatters: formatters,
      validator: validator,
      style: const TextStyle(
          color: AppColors.primary, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11, color: AppColors.lightGrey),
        floatingLabelStyle:
            const TextStyle(fontSize: 13, color: AppColors.primary),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        enabledBorder: border(const Color(0xFFDDDDDD)),
        focusedBorder: border(AppColors.primary, 1.4),
        errorBorder: border(AppColors.expense),
        focusedErrorBorder: border(AppColors.expense, 1.4),
      ),
    );
  }

  // ---------------- Аккаунт ----------------

  List<Widget> _accountTab() {
    return [
      for (int i = 0; i < _accounts.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: GestureDetector(
            onTap: () => setState(() => _account = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _account == i
                    ? AppColors.pill
                    : const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _account == i
                          ? Colors.white
                          : const Color(0xFFF0F0F0),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_accounts[i].$1,
                        size: 30,
                        color: _account == i
                            ? AppColors.primary
                            : const Color(0xFF888888)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_accounts[i].$2,
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: _account == i
                                    ? AppColors.primary
                                    : AppColors.grey)),
                        const SizedBox(height: 4),
                        Text(_accounts[i].$3,
                            style: TextStyle(
                                fontSize: 12,
                                color: _account == i
                                    ? AppColors.primary
                                    : AppColors.lightGrey)),
                      ],
                    ),
                  ),
                  if (_account == i)
                    const Icon(Icons.check_circle,
                        color: AppColors.primary, size: 26),
                ],
              ),
            ),
          ),
        ),
      const SizedBox(height: 40),
      OutlinePillButton(
        label: 'ДАРААХ',
        loading: _loading,
        onPressed: _submitAccount,
      ),
    ];
  }
}

/// Картын дугаарыг 4 оронгоор бүлэглэнэ: "6219 8610 2888 8075".
class _GroupFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _CardPreview extends StatelessWidget {
  final String holder;
  final String number;
  final String expiry;
  const _CardPreview({
    required this.holder,
    required this.number,
    required this.expiry,
  });

  @override
  Widget build(BuildContext context) {
    const mono = TextStyle(
      color: Colors.white,
      fontFamily: 'monospace',
      fontWeight: FontWeight.w600,
    );
    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          Positioned(
            left: 34,
            right: 34,
            top: 0,
            child: Container(
              height: 60,
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('VISA',
                      style: mono.copyWith(
                          fontSize: 16, fontStyle: FontStyle.italic)),
                  const Spacer(),
                  Text('Mono', style: mono.copyWith(fontSize: 12)),
                ],
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 28,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2F7E79), Color(0xFF4FB3A6)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Debit\nCard', style: mono.copyWith(fontSize: 13)),
                      const Spacer(),
                      Text('Mono', style: mono.copyWith(fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 34,
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6E6E6),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Icon(Icons.memory,
                        size: 20, color: Color(0xFF9A9A9A)),
                  ),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(number,
                        style: mono.copyWith(fontSize: 18, letterSpacing: 3)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(holder.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: mono.copyWith(
                                fontSize: 13, letterSpacing: 1.5)),
                      ),
                      Text(expiry, style: mono.copyWith(fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
