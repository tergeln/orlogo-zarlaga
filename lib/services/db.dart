import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models.dart';

/// Firestore бүтэц:
///   users/{uid}                     — нэр, имэйл
///   users/{uid}/transactions/{id}   — орлого, зарлага, түрийвч цэнэглэлт
///   users/{uid}/bills/{id}          — хүлээгдэж буй төлбөрүүд
///   users/{uid}/receipts/{id}       — төлбөрийн баримтууд
///   users/{uid}/cards/{id}          — холбосон картууд (зөвхөн сүүлийн 4 орон)
class Db {
  static final _db = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> get _user =>
      _db.collection('users').doc(FirebaseAuth.instance.currentUser!.uid);

  static Future<void> createUser(String name, String email) async {
    final now = DateTime.now();
    final batch = _db.batch();
    batch.set(_user, {
      'name': name,
      'email': email,
      'createdAt': Timestamp.fromDate(now),
    });
    DateTime due(int days) => now.add(Duration(days: days));
    final bills = [
      {'name': 'Youtube Premium', 'price': 11.99, 'fee': 1.99, 'dueDate': due(7)},
      {'name': 'Electricity', 'price': 45.00, 'fee': 1.00, 'dueDate': due(14)},
      {'name': 'House Rent', 'price': 500.00, 'fee': 0.00, 'dueDate': due(21)},
      {'name': 'Spotify', 'price': 9.99, 'fee': 1.00, 'dueDate': due(28)},
    ];
    for (final b in bills) {
      batch.set(_user.collection('bills').doc(), {
        ...b,
        'dueDate': Timestamp.fromDate(b['dueDate'] as DateTime),
        'paid': false,
      });
    }
    await batch.commit();
  }

  static Stream<List<TxModel>> transactions() => _user
      .collection('transactions')
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map(TxModel.fromDoc).toList());

  static Future<Totals> totals() async {
    final s = await _user.collection('transactions').get();
    return Totals.of(s.docs.map(TxModel.fromDoc).toList());
  }

  static Stream<List<Bill>> pendingBills() =>
      _user.collection('bills').orderBy('dueDate').snapshots().map(
          (s) => s.docs.map(Bill.fromDoc).where((b) => !b.paid).toList());

  /// Шинэ хүлээгдэж буй төлбөр нэмэх.
  static Future<void> addBill({
    required String name,
    required double price,
    required double fee,
    required DateTime dueDate,
  }) {
    return _user.collection('bills').add({
      'name': name,
      'price': price,
      'fee': fee,
      'dueDate': Timestamp.fromDate(dueDate),
      'paid': false,
    });
  }

  static Stream<List<Receipt>> receipts() => _user
      .collection('receipts')
      .orderBy('paidAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Receipt.fromDoc).toList());

  static Future<void> addTransaction({
    required String title,
    required double amount,
    required bool isIncome,
    required DateTime date,
    String? source,
  }) {
    return _user.collection('transactions').add({
      'title': title,
      'amount': amount,
      'type': isIncome ? 'income' : 'expense',
      'date': Timestamp.fromDate(date),
      if (source != null) 'source': source,
    });
  }

  /// Түрийвч цэнэглэх: орлогын гүйлгээ болж хадгалагдана.
  static Future<void> topUp(double amount, String source) => addTransaction(
        title: 'Түрийвч цэнэглэлт',
        amount: amount,
        isIncome: true,
        date: DateTime.now(),
        source: source,
      );

  /// Картын мэдээллээс зөвхөн эзэмшигчийн нэр, сүүлийн 4 орон, хугацааг хадгална.
  static Future<void> saveCard({
    required String brand,
    required String holder,
    required String last4,
    required String expiry,
  }) {
    return _user.collection('cards').doc('${brand}_$last4').set({
      'brand': brand,
      'holder': holder,
      'last4': last4,
      'expiry': expiry,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Хадгалсан бүх карт, сүүлд нэмсэн нь эхэндээ.
  static Stream<List<SavedCard>> cards() => _user
      .collection('cards')
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(SavedCard.fromDoc).toList());

  static Future<void> deleteCard(String id) =>
      _user.collection('cards').doc(id).delete();

  /// Төлбөр төлөх: зарлагын гүйлгээ + баримт үүсгэж, төлбөрийг төлөгдсөн болгоно.
  static Future<Receipt> payBill(Bill bill, String method) async {
    final now = DateTime.now();
    final number =
        '${now.millisecondsSinceEpoch}${Random().nextInt(900) + 100}';
    final receiptRef = _user.collection('receipts').doc();
    final receipt = Receipt(
      id: receiptRef.id,
      billName: bill.name,
      price: bill.price,
      fee: bill.fee,
      method: method,
      paidAt: now,
      number: number,
    );
    final batch = _db.batch();
    batch.set(_user.collection('transactions').doc(), {
      'title': bill.name,
      'amount': bill.total,
      'type': 'expense',
      'date': Timestamp.fromDate(now),
      'source': method,
      'receiptId': receiptRef.id,
    });
    batch.set(receiptRef, receipt.toMap());
    batch.update(_user.collection('bills').doc(bill.id), {
      'paid': true,
      'paidAt': Timestamp.fromDate(now),
    });
    await batch.commit();
    return receipt;
  }
}
