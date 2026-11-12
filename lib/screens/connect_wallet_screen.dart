import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../services/db.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Картын төрлүүд ба тус бүрийн өнгө.
const _brands = ['VISA', 'Mastercard', 'UnionPay'];

List<Color> _brandColors(String brand) {
  switch (brand) {
    case 'Mastercard':
      return const [Color(0xFF1F4F5C), Color(0xFF4A93A6)];
    case 'UnionPay':
      return const [Color(0xFF35607A), Color(0xFF63B5AF)];
    default:
      return const [Color(0xFF2F7E79), Color(0xFF4FB3A6)];
  }
}

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

  // Хадгалсан картууд + сүүлийн хуудас нь "шинэ карт".
  List<SavedCard> _cards = const [];
  StreamSubscription<List<SavedCard>>? _cardsSub;
  final _pager = PageController(viewportFraction: 0.94);
  int _page = 0;
  String _brand = _brands.first;

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

  bool get _isNew => _page >= _cards.length;

  @override
  void initState() {
    super.initState();
    _name.addListener(_refresh);
    _number.addListener(_refresh);
    _expiry.addListener(_refresh);
    _cardsSub = Db.cards().listen((cards) {
      if (!mounted) return;
      setState(() {
        _cards = cards;
        if (_page > cards.length) _page = cards.length;
      });
    }, onError: (_) {});
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _cardsSub?.cancel();
    _pager.dispose();
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

  /// Шинэ карт хадгална. Дүн оруулсан бол түрийвчийг мөн цэнэглэнэ.
  Future<void> _submitNewCard() async {
    if (!_form.currentState!.validate()) return;
    final digits = _number.text.replaceAll(' ', '');
    final last4 = digits.substring(digits.length - 4);
    final amount = _parse(_value.text);
    setState(() => _loading = true);
    try {
      await Db.saveCard(
        brand: _brand,
        holder: _name.text.trim(),
        last4: last4,
        expiry: _expiry.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showMessage(context, 'Карт хадгалагдсангүй: $e');
      return;
    }
    if (!mounted) return;
    if (amount != null) {
      await _topUp(amount, 'Карт $_brand •••• $last4');
      return;
    }
    _name.clear();
    _number.clear();
    _cvc.clear();
    _expiry.clear();
    setState(() {
      _loading = false;
      _page = 0;
    });
    if (_pager.hasClients) _pager.jumpToPage(0);
    showMessage(context, 'Карт хадгалагдлаа.');
  }

  /// Сонгосон хадгалсан картаар цэнэглэнэ.
  Future<void> _submitSavedCard() async {
    final amount = _parse(_value.text);
    if (amount == null) {
      showMessage(context, 'Цэнэглэх дүнгээ оруулна уу.');
      return;
    }
    await _topUp(amount, 'Карт ${_cards[_page].label}');
  }

  Future<void> _deleteCard(SavedCard card) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Карт устгах уу?'),
        content: Text('${card.label} картыг жагсаалтаас хасна.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Болих'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Устгах'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Db.deleteCard(card.id);
    } catch (e) {
      if (mounted) showMessage(context, 'Алдаа гарлаа: $e');
    }
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
        padding: const EdgeInsets.fromLTRB(0, 28, 0, 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: SegmentTabs(
              labels: const ['Картууд', 'Аккаунт'],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
          ),
          const SizedBox(height: 22),
          if (_tab == 0)
            ..._cardTab()
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(children: _accountTab()),
            ),
        ],
      ),
    );
  }

  // ---------------- Картууд ----------------

  List<Widget> _cardTab() {
    final count = _cards.length + 1;
    return [
      SizedBox(
        height: 222,
        child: PageView.builder(
          controller: _pager,
          itemCount: count,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) {
            if (i < _cards.length) {
              final c = _cards[i];
              return _CardPreview(
                brand: c.brand,
                holder: c.holder.isEmpty ? '—' : c.holder,
                number: c.masked,
                expiry: c.expiry,
              );
            }
            return _CardPreview(
              brand: _brand,
              holder:
                  _name.text.trim().isEmpty ? 'НЭР ОВОГ' : _name.text.trim(),
              number: _number.text.trim().isEmpty
                  ? '•••• •••• •••• ••••'
                  : _number.text.trim(),
              expiry:
                  _expiry.text.trim().isEmpty ? 'YYYY/MM' : _expiry.text.trim(),
              isNew: true,
            );
          },
        ),
      ),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _page ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: i == _page ? AppColors.primary : const Color(0xFFD5DEDD),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
        ],
      ),
      const SizedBox(height: 18),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _isNew
              ? KeyedSubtree(
                  key: const ValueKey('new'), child: _newCardForm())
              : KeyedSubtree(
                  key: ValueKey(_cards[_page].id),
                  child: _savedCardPanel(_cards[_page])),
        ),
      ),
    ];
  }

  Widget _savedCardPanel(SavedCard card) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Сонгосон карт: ${card.label}',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            IconButton(
              tooltip: 'Карт устгах',
              onPressed: () => _deleteCard(card),
              icon: const Icon(Icons.delete_outline, color: AppColors.expense),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _cards.length > 1
              ? 'Зүүн, баруун тийш гүйлгэж өөр карт сонгоно. Сүүлийн хуудсанд шинэ карт нэмнэ.'
              : 'Баруун тийш гүйлгэж шинэ карт нэмнэ.',
          style: const TextStyle(fontSize: 13, color: AppColors.grey),
        ),
        const SizedBox(height: 16),
        _field(
          controller: _value,
          label: 'ЦЭНЭГЛЭХ ДҮН \$',
          keyboard: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 22),
        OutlinePillButton(
          label: 'ИЛГЭЭХ',
          loading: _loading,
          onPressed: _submitSavedCard,
        ),
      ],
    );
  }

  Widget _newCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Картны мэдээллээ нэмэх',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        const Text('Энд холбох карт нь зөвхөн таны нэр дээр байх ёстой.',
            style: TextStyle(fontSize: 13, color: AppColors.grey)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          children: [
            for (final b in _brands)
              ChoiceChip(
                label: Text(b),
                selected: _brand == b,
                onSelected: (_) => setState(() => _brand = b),
                selectedColor: AppColors.pill,
                backgroundColor: Colors.white,
                showCheckmark: false,
                side: BorderSide(
                    color: _brand == b
                        ? AppColors.primary
                        : const Color(0xFFDDDDDD)),
                labelStyle: TextStyle(
                  color: _brand == b ? AppColors.primary : AppColors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Form(
          key: _form,
          child: Column(
            children: [
              _field(
                controller: _name,
                label: 'КАРТ ДЭЭРХ НЭР',
                capitalization: TextCapitalization.characters,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Нэрээ оруулна уу'
                    : null,
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
                      keyboard: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) =>
                          (v ?? '').trim().isNotEmpty && _parse(v!) == null
                              ? 'Дүн буруу'
                              : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Дүнг хоосон орхивол карт зөвхөн хадгалагдана.',
          style: TextStyle(fontSize: 12, color: AppColors.lightGrey),
        ),
        const SizedBox(height: 16),
        OutlinePillButton(
          label: 'ИЛГЭЭХ',
          loading: _loading,
          onPressed: _submitNewCard,
        ),
      ],
    );
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
  final String brand;
  final String holder;
  final String number;
  final String expiry;
  final bool isNew;
  const _CardPreview({
    required this.brand,
    required this.holder,
    required this.number,
    required this.expiry,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    const mono = TextStyle(
      color: Colors.white,
      fontFamily: 'monospace',
      fontWeight: FontWeight.w600,
    );
    final colors = _brandColors(brand);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Stack(
        children: [
          Positioned(
            left: 22,
            right: 22,
            top: 0,
            child: Container(
              height: 60,
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
              decoration: BoxDecoration(
                color: colors.last.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(brand.toUpperCase(),
                      style: mono.copyWith(
                          fontSize: 15, fontStyle: FontStyle.italic)),
                  const Spacer(),
                  Text('Mono', style: mono.copyWith(fontSize: 12)),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 28,
            bottom: 8,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.first.withValues(alpha: 0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isNew ? 'New\nCard' : 'Debit\nCard',
                          style: mono.copyWith(fontSize: 13)),
                      const Spacer(),
                      Text(brand,
                          style: mono.copyWith(
                              fontSize: 15, fontStyle: FontStyle.italic)),
                    ],
                  ),
                  const SizedBox(height: 10),
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
