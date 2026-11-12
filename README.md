# orlogo-zarlaga

Хувь хүний Орлого & Зарлага хянах апп — Flutter + Firebase.

## Дэлгэцүүд

Splash, Onboarding, Register, Login, Homepage, Wallet (гүйлгээ / хүлээгдэж буй төлбөр),
Connect Wallet (карт / аккаунт), Add Expense, Bill Details, Bill Payment, баримт + QR.

## Firebase

- Authentication: имэйл / нууц үгээр бүртгэл, нэвтрэлт
- Cloud Firestore: `users/{uid}` доторх `transactions`, `bills`, `receipts`, `cards`
- Аюулгүй байдлын дүрэм: `firestore.rules`

## Ажиллуулах

```bash
flutter pub get
flutter run
```
