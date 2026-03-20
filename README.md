# BudgetO - Daily Expense Tracker 💰

A clean, modern, and dark-themed Flutter application to manage daily expenses and financial notes. Built with a focus on simplicity and local data privacy.

## ✨ Features
- **Dashboard:** Real-time visualization of spending via a Pie Chart.
- **Rupee Support:** All transactions and totals are displayed in ₹.
- **Smart Filtering:** Search by name/category and filter by specific dates.
- **Local Storage:** Uses Hive (NoSQL) for lightning-fast, offline data saving.
- **Notes Section:** Quick access to financial reminders and goals.
- **Custom Categories:** Ability to add your own categories on the fly.

## 🛠️ Tech Stack
- **Framework:** Flutter (Material 3)
- **Language:** Dart
- **State Management:** Provider
- **Database:** Hive & Hive Flutter
- **Charts:** FL Chart

## 🚀 How to Run
1. **Clone the project** and open it in VS Code.
2. Run `flutter pub get` in the terminal to download dependencies.
3. Run the code generator for the database:
   `dart run build_runner build`
4. Connect your phone or emulator and press `F5`.

## 📱 How to Build the APK
Run the following command in your terminal:
`flutter build apk --split-per-abi`
The file will be located in `build/app/outputs/flutter-apk/app-release.apk`.