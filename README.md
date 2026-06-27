# Sajilo Share 💸

Sajilo Share is a beautiful, intuitive Flutter app designed to make splitting bills and sharing expenses with roommates or friends absolutely effortless. 

Whether you're managing rent, groceries, or travel expenses, Sajilo Share automatically calculates exactly who owes whom, tracks receipts, and provides clear analytics—all wrapped in a premium, modern user interface.

## 🌟 Key Features

*   **Group Rooms:** Create dedicated "rooms" for different groups (e.g., "The Penthouse", "Goa Trip") and invite members to join via shareable codes.
*   **Smart Splitting:** Add expenses and choose how they are split—equally amongst everyone, or only between specific members.
*   **Global Dues:** Instantly see a centralized breakdown of exactly who you owe and who owes you across *all* your different rooms, all in one place.
*   **Receipt Attachments (No Cloud Storage Required):** Snap a photo of a receipt when adding an expense. Images are heavily compressed and stored directly as Base64 strings in the database, entirely bypassing expensive cloud storage limits.
*   **Analytics Dashboard:** View beautiful, interactive charts summarizing your group spending by category (Food, Utilities, Rent, etc.) and filter them by month.
*   **Personal Expenses:** Keep track of your own private, non-shared expenses alongside your group dues.
*   **Decimal Support:** Exact money formatting supporting decimals so nobody is fighting over the last few cents!

## 🚀 Tech Stack

*   **Frontend:** [Flutter](https://flutter.dev/) & Dart
*   **State Management:** Riverpod
*   **Backend / Database:** Firebase Authentication & Cloud Firestore
*   **Routing:** GoRouter
*   **Charts:** fl_chart

## 📸 Screenshots
*(Coming soon)*

## 🛠️ Getting Started

Because this project relies on Firebase, you will need to set up your own Firebase project to run it locally.

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Ranjitdon/Sajilo-Share.git
   cd Sajilo-Share
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   * Create a project in the [Firebase Console](https://console.firebase.google.com/).
   * Enable **Authentication** (Email/Password & Google Sign-In).
   * Enable **Firestore Database**.
   * Run `flutterfire configure` in the root of the project to generate your `firebase_options.dart` file.

4. **Run the App:**
   ```bash
   flutter run
   ```

## 📝 License
This project is for personal use and learning purposes.
