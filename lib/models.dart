import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _date(dynamic v) => v is Timestamp ? v.toDate() : DateTime.now();
double _num(dynamic v) => v is num ? v.toDouble() : 0;

/// Орлого эсвэл зарлагын нэг гүйлгээ.
class TxModel {
  final String id;
  final String title;
  final double amount;
  final bool isIncome;
  final DateTime date;

  const TxModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.date,
  });

  factory TxModel.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return TxModel(
      id: d.id,
      title: (m['title'] ?? '') as String,
      amount: _num(m['amount']),
      isIncome: m['type'] == 'income',
      date: _date(m['date']),
    );
  }
}

class Totals {
  final double income;
  final double expense;
  const Totals(this.income, this.expense);
  double get balance => income - expense;

  factory Totals.of(List<TxModel> list) {
    double i = 0, e = 0;
    for (final t in list) {
      if (t.isIncome) {
        i += t.amount;
      } else {
        e += t.amount;
      }
    }
    return Totals(i, e);
  }
}

/// Хүлээгдэж буй төлбөр (bill).
class Bill {
  final String id;
  final String name;
  final double price;
  final double fee;
  final DateTime dueDate;
  final bool paid;

  const Bill({
    required this.id,
    required this.name,
    required this.price,
    required this.fee,
    required this.dueDate,
    required this.paid,
  });

  double get total => price + fee;

  factory Bill.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return Bill(
      id: d.id,
      name: (m['name'] ?? '') as String,
      price: _num(m['price']),
      fee: _num(m['fee']),
      dueDate: _date(m['dueDate']),
      paid: m['paid'] == true,
    );
  }
}

/// Хадгалсан карт. Бүтэн дугаар, CVC хадгалагдахгүй.
class SavedCard {
  final String id;
  final String brand;
  final String holder;
  final String last4;
  final String expiry;

  const SavedCard({
    required this.id,
    required this.brand,
    required this.holder,
    required this.last4,
    required this.expiry,
  });

  String get masked => '•••• •••• •••• $last4';
  String get label => '$brand •••• $last4';

  factory SavedCard.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return SavedCard(
      id: d.id,
      brand: (m['brand'] ?? 'VISA') as String,
      holder: (m['holder'] ?? '') as String,
      last4: (m['last4'] ?? '') as String,
      expiry: (m['expiry'] ?? '') as String,
    );
  }
}

/// Төлбөрийн баримт.
class Receipt {
  final String id;
  final String billName;
  final double price;
  final double fee;
  final String method;
  final DateTime paidAt;
  final String number;

  const Receipt({
    required this.id,
    required this.billName,
    required this.price,
    required this.fee,
    required this.method,
    required this.paidAt,
    required this.number,
  });

  double get total => price + fee;

  Map<String, dynamic> toMap() => {
        'billName': billName,
        'price': price,
        'fee': fee,
        'total': total,
        'method': method,
        'status': 'Хийгдсэн',
        'paidAt': Timestamp.fromDate(paidAt),
        'number': number,
      };

  factory Receipt.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return Receipt(
      id: d.id,
      billName: (m['billName'] ?? '') as String,
      price: _num(m['price']),
      fee: _num(m['fee']),
      method: (m['method'] ?? '') as String,
      paidAt: _date(m['paidAt']),
      number: (m['number'] ?? '') as String,
    );
  }

  /// QR код дотор хадгалагдах текст. Сканнерууд найдвартай уншдаг байхын тулд
  /// зөвхөн латин үсэг ашиглана.
  String get qrData {
    String two(int v) => v.toString().padLeft(2, '0');
    final date = '${paidAt.year}-${two(paidAt.month)}-${two(paidAt.day)} '
        '${two(paidAt.hour)}:${two(paidAt.minute)}';
    final methodLatin = method == 'Түрийвч' ? 'Wallet' : 'Debit card';
    final item = billName.replaceAll(RegExp(r'[^\x20-\x7E]'), '?');
    return [
      'ORLOGO ZARLAGA - RECEIPT',
      'No: $number',
      'Item: $item',
      'Price: \$${price.toStringAsFixed(2)}',
      'Fee: \$${fee.toStringAsFixed(2)}',
      'Total: \$${total.toStringAsFixed(2)}',
      'Paid by: $methodLatin',
      'Date: $date',
      'Status: Paid',
    ].join('\n');
  }
}
