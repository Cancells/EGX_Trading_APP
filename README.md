Markdown
# 📈 Statch - Egyptian Market Tracker

![Statch Banner](assets/images/icon.png)

**Statch** is a modern, Flutter-based financial tracking application designed specifically for the Egyptian market. It allows users to track **EGX Stock prices**, **Live Gold rates**, and **Cryptocurrency** trends while managing a personal investment portfolio with real-time gain/loss analysis.

Built with **Material 3**, Dynamic Color (Material You), and a clean glassmorphism aesthetic.

---

## 🚀 Features

### 📊 Market Tracking
* **EGX Stocks:** Track over 80+ Egyptian companies (COMI, FWRY, EAST, etc.) with ticker data loaded dynamically.
* **Gold Prices:** Live tracking of Gold 24K, 21K, 18K, and the Gold Pound.
* **Crypto & US Markets:** Tabs for tracking global assets (Simulated/API integrated).
* **Interactive Charts:** Sparklines and detailed intraday price charts using `fl_chart`.

### 💼 Portfolio Management
* **Holdings:** Add assets with purchase date, quantity, and price.
* **Performance:** Real-time calculation of Total Gain/Loss, Daily Change, and Portfolio Value.
* **Privacy Mode:** Hide sensitive balance information with a single tap (Biometric-ready).

### 🎨 Modern UI/UX
* **Material You:** Dynamic theming that adapts to your device's wallpaper (Android 12+).
* **Themes:** Full support for Light and Dark modes.
* **Glassmorphism:** Premium frosted glass effects on cards and overlays.
* **Haptic Feedback:** Tactile responses for interactions.
* **Shimmer Loading:** Smooth skeleton loading states for better perceived performance.

### 🔒 Security
* **App Lock:** Secure the app with a PIN code.
* **Biometrics:** Optional Fingerprint/Face ID unlock.
* **Secure Storage:** Sensitive data encrypted using `flutter_secure_storage`.

---

## 🛠️ Tech Stack

* **Framework:** [Flutter](https://flutter.dev/) (Dart)
* **State Management:** [Provider](https://pub.dev/packages/provider)
* **Architecture:** Service-Oriented Architecture (MVVM-style)
* **UI Components:** `fl_chart`, `shimmer`, `flutter_animate`, `dynamic_color`.
* **Data & Networking:** `http`, `shared_preferences`, `flutter_secure_storage`.
* **Assets:** Local JSON data handling for tickers.

---

## 📸 Screenshots

| Dashboard (Light) | Dashboard (Dark) | Asset Detail |
|:---:|:---:|:---:|
| | | |
| ![Light Mode](https://via.placeholder.com/200x400?text=Light+Mode) | ![Dark Mode](https://via.placeholder.com/200x400?text=Dark+Mode) | ![Detail](https://via.placeholder.com/200x400?text=Detail+View) |

---

## 📂 Project Structure

```text
lib/
├── main.dart                 # Application entry point
├── models/                   # Data models (Stock, Investment, MarketData)
├── repositories/             # Data fetching repositories
├── screens/                  # UI Screens (Dashboard, Portfolio, Settings)
├── services/                 # Business Logic (YahooFinance, Gold, Preferences)
├── theme/                    # App Theme & Dynamic Color logic
├── utils/                    # Helpers (Icon generation, Formatters)
└── widgets/                  # Reusable UI components (Cards, Charts)
assets/
└── data/                     # JSON files (egx_tickers.json, etc.)
⚡ Installation
Prerequisites:

Flutter SDK installed (v3.5.0 or higher recommended).

Android Studio / VS Code.

Clone the repository:

Bash
git clone [https://github.com/yourusername/statch.git](https://github.com/yourusername/statch.git)
cd statch
Install dependencies:

Bash
flutter pub get
Run the app:

Bash
flutter run
⚙️ Configuration
App Icon Generation
The app includes a built-in script to generate its own logo using code. To regenerate the icon:

Uncomment IconGenerator.generateAndSaveIcon(); in main.dart.

Run the app.

Retrieve the file from device storage or use flutter_launcher_icons to apply it.

Data Sources
Stocks: Uses Yahoo Finance API (scraped/unofficial).

Tickers: Loaded from assets/data/egx_tickers.json. To add a stock, simply append it to this JSON file.

🤝 Contributing
Contributions are welcome!

Fork the Project.

Create your Feature Branch (git checkout -b feature/AmazingFeature).

Commit your Changes (git commit -m 'Add some AmazingFeature').

Push to the Branch (git push origin feature/AmazingFeature).

Open a Pull Request.

📄 License
Distributed under the MIT License. See LICENSE for more information.

Built with ❤️ for the Egyptian Investor Community.