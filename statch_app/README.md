# Statch - Egyptian Market Trading App

A production-ready Flutter Android app with Robinhood-style design, featuring real-time Egyptian market data visualization.

![Statch App](https://img.shields.io/badge/Flutter-3.24.3-blue) ![Platform](https://img.shields.io/badge/Platform-Android-green) ![License](https://img.shields.io/badge/License-MIT-yellow)

## 🎨 Design System

- **Primary Color**: `#00C805` (Robinhood Green)
- **Secondary Color**: `#FF5000` (Robinhood Red - for dips)
- **Background Dark**: `#000000` (True Black)
- **Background Light**: `#FAFAFA` (Off-White)
- **Icons**: Material Symbols (Rounded) with weight 300
- **Typography**: Inter (via Google Fonts)

## ✨ Features

### Core Infrastructure
- **Mock Market Service**: Real-time streaming of 2026 Egyptian market data
  - EGX 30 Index: ~41,500 EGP
  - Gold 24K: ~6,850 EGP/g
  - Gold 21K: ~6,000 EGP/g
  - Stocks: COMI, TMGH, ETEL, FWRY with realistic EGP prices

- **Error Debug Overlay**: On-screen error display for APK debugging

### High-Fidelity Dashboard
- **Interactive Chart**: fl_chart implementation with:
  - Animation on load
  - Color change based on daily trend (Green vs Red)
  - Long Press + Drag gesture for price inspection
  - Vertical indicator line with price tooltip

- **Gold Cards**: Premium design with gradient backgrounds and gold ingot icons

### Navigation & Profile
- **Top-Right Navigation**: CircleAvatar with custom modal menu
- **Profile Screen**: Edit name, avatar, and DOB
- **Settings Screen**: Theme toggle, notification settings
- **About Screen**: App version and credits

### Production Polish
- Hero animations for screen transitions
- AnimatedContainer for price changes
- AnimatedSwitcher for smooth value updates
- Custom StatchLogo using CustomPainter

## 📁 Project Structure

```
lib/
├── main.dart                     # App entry point with error handling
├── models/
│   └── market_data.dart          # Data models (MarketIndex, GoldPrice, Stock)
├── services/
│   ├── market_data_service.dart  # Mock market data streaming service
│   └── preferences_service.dart  # Shared preferences wrapper
├── screens/
│   ├── dashboard_screen.dart     # Main dashboard with charts
│   ├── profile_screen.dart       # User profile editor
│   ├── settings_screen.dart      # App settings
│   └── about_screen.dart         # About & credits
├── widgets/
│   ├── error_overlay.dart        # Debug error banner
│   ├── gold_card.dart            # Gold price card widget
│   ├── mini_chart.dart           # Sparkline chart for stocks
│   ├── price_chart.dart          # Main interactive chart
│   ├── statch_logo.dart          # Custom logo painter
│   └── stock_card.dart           # Stock price card
└── theme/
    └── app_theme.dart            # Theme configuration
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.24.3 or later
- Android SDK
- JDK 17

### Installation

1. Clone the repository
```bash
cd statch_app
```

2. Get dependencies
```bash
flutter pub get
```

3. Run the app
```bash
flutter run
```

### Build Release APK

```bash
flutter build apk --release
```

The APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`

## 📱 Screenshots

The app features:
- Dark and light mode support
- Interactive price charts
- Gold price cards with gradient backgrounds
- Stock list with mini sparklines
- Profile customization
- Settings with toggle switches

## 🛠️ Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| fl_chart | ^0.68.0 | Interactive charts |
| shared_preferences | ^2.2.3 | Local storage |
| intl | ^0.19.0 | Date formatting |
| google_fonts | ^6.2.1 | Inter font family |

## 🎯 Key Implementation Details

### Error Overlay
```dart
ErrorOverlay.showError("Error message");
ErrorOverlay.showErrorWithAutoDismiss("Message", duration: Duration(seconds: 5));
```

### Market Data Stream
```dart
MarketDataService().marketDataStream.listen((data) {
  // Handle real-time market data
});
```

### Theme Toggle
```dart
PreferencesService().setDarkMode(true);
```

## 📝 License

This project is licensed under the MIT License.

## 🙏 Credits

Built with ❤️ for Egyptian Investors

- Powered by Flutter & Dart
- Charts by fl_chart
- Typography by Google Fonts
