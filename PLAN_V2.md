# Statch App V2 - Advanced Upgrade Plan

## Overview
Evolving the investment app into a high-performance, personalized financial dashboard with Material You design, enhanced security, and advanced real-time data.

---

## Task 1: Personalization & Material You (Design 3)

### 1.1 Material You Implementation
- **Package:** `dynamic_color` for dynamic theming
- **File:** `lib/theme/dynamic_theme.dart`
- **Features:**
  - Detect Android 12+ for dynamic color support
  - Extract device wallpaper colors
  - Fall back to "Emerald & Charcoal" brand theme
  - Update `AppTheme` to support dynamic ColorScheme

### 1.2 Profile Sync
- **File:** `lib/services/preferences_service.dart` (update)
- **Features:**
  - Store selected avatar type (icon/custom image)
  - Store custom image path
  - Global profile notifier for real-time sync

### 1.3 Custom Avatar Selection
- **File:** `lib/screens/profile_screen.dart` (update)
- **Features:**
  - Financial-themed avatar set (chart, coin, bank, portfolio icons)
  - Image picker for custom photos
  - Circular crop/preview
  - Store in app documents directory

---

## Task 2: Advanced Real-Time Data

### 2.1 Egyptian Gold Logic
- **File:** `lib/services/gold_service.dart` (new)
- **Formula:** `24K_Price_per_gram * (Karat / 24)`
- **Karats:** 18K, 21K, 24K
- **Display:**
  - Purchase Price
  - Current Market Price
  - Gain/Loss per Karat
- **Data Source:** Fetch USD gold spot, convert via EGP exchange rate

### 2.2 Market Switcher
- **File:** `lib/widgets/market_switcher.dart` (new)
- **Markets:**
  - US (Nasdaq/NYSE): AAPL, GOOGL, MSFT, AMZN, TSLA
  - EGX 30: COMI.CA, TMGH.CA, ETEL.CA, FWRY.CA
  - EGX 100: Extended Egyptian stocks
- **Widget:** SegmentedButton or TabBar
- **State:** Market selection persisted in preferences

### 2.3 Stock Chip Design
- **File:** `lib/widgets/stock_chip.dart` (new)
- **Features:**
  - Company logo (via Logo API or initials placeholder)
  - Ticker symbol
  - Current price
  - Change indicator (up/down arrow with color)
- **Logo API:** `https://logo.clearbit.com/{domain}` or fallback to initials

---

## Task 3: Security & Privacy

### 3.1 Biometric Lock
- **Package:** `local_auth`
- **File:** `lib/screens/security_gate_screen.dart` (new)
- **Features:**
  - Fingerprint authentication
  - FaceID support
  - 4-digit PIN fallback
  - "Remember me" toggle for session persistence
- **Flow:** Welcome → Security Gate → Dashboard

### 3.2 PIN Service
- **File:** `lib/services/pin_service.dart` (new)
- **Features:**
  - Secure PIN storage (hashed)
  - PIN setup flow
  - PIN verification
  - Lockout after 5 failed attempts

### 3.3 Currency Settings
- **File:** `lib/services/currency_service.dart` (new)
- **Currencies:** EGP, USD, EUR
- **Features:**
  - Live exchange rate fetching
  - Global currency preference
  - All P/L calculations converted to base currency
  - Currency symbol formatting

---

## Task 4: Bottom Navigation & Portfolio

### 4.1 Bottom Navigation Bar
- **File:** `lib/screens/main_shell.dart` (new)
- **Tabs:**
  - Home (Dashboard)
  - Portfolio (Investments)
  - Settings
- **Features:**
  - Material 3 NavigationBar
  - Persistent state across tabs
  - Badge indicators for alerts

### 4.2 Interactive Portfolio
- **File:** `lib/screens/stock_detail_screen.dart` (new)
- **Features:**
  - Real-time price graph (1D/1W/1M)
  - Company info card
  - Investment details
  - Edit investment functionality

### 4.3 Edit Investment Widget
- **File:** `lib/widgets/edit_investment_sheet.dart` (new)
- **Features:**
  - Manual price override
  - Auto-calculate units from total amount
  - Formula: `Units = Total_Investment / Price_Per_Unit`
  - Update investment record

---

## Technical Architecture

### State Management (Provider)
```
lib/providers/
├── theme_provider.dart       # Dynamic theme state
├── market_provider.dart      # Real-time market data
├── portfolio_provider.dart   # Investment state
├── currency_provider.dart    # Currency conversion
└── auth_provider.dart        # Security state
```

### Service Layer
```
lib/services/
├── yahoo_finance_service.dart  # (existing)
├── gold_service.dart           # Egyptian gold pricing
├── currency_service.dart       # Exchange rates
├── pin_service.dart            # PIN management
├── image_service.dart          # Avatar management
└── preferences_service.dart    # (updated)
```

### 10-Second Polling Strategy
- Use `Timer.periodic` in providers
- Debounce UI updates
- Only update changed values (diffing)
- Pause polling when app backgrounded
- Resume on foreground

---

## Dependencies to Add

```yaml
dependencies:
  dynamic_color: ^1.7.0         # Material You
  local_auth: ^2.2.0            # Biometrics
  image_picker: ^1.0.7          # Custom avatars
  path_provider: ^2.1.2         # File storage
  crypto: ^3.0.3                # PIN hashing
  cached_network_image: ^3.3.1  # Logo caching
```

---

## Implementation Order

### Phase 1: Foundation & Navigation
- [ ] Add new dependencies to pubspec.yaml
- [ ] Create MainShell with BottomNavigationBar
- [ ] Restructure app navigation flow
- [ ] Update main.dart routing

### Phase 2: Material You & Theme
- [ ] Create DynamicThemeProvider
- [ ] Update AppTheme with dynamic support
- [ ] Implement fallback brand theme
- [ ] Test on Android 12+ and older devices

### Phase 3: Security Gate
- [ ] Create PinService
- [ ] Create SecurityGateScreen
- [ ] Implement biometric authentication
- [ ] Add PIN fallback
- [ ] Integrate into app flow

### Phase 4: Profile & Avatar
- [ ] Create ImageService
- [ ] Update ProfileScreen with new avatars
- [ ] Add image picker integration
- [ ] Sync avatar across app

### Phase 5: Advanced Market Data
- [ ] Create GoldService with Egyptian pricing
- [ ] Create MarketSwitcher widget
- [ ] Create StockChip widget
- [ ] Update dashboard with market selection

### Phase 6: Currency & Conversion
- [ ] Create CurrencyService
- [ ] Add currency settings to Settings
- [ ] Update all P/L calculations
- [ ] Display in selected currency

### Phase 7: Interactive Portfolio
- [ ] Create StockDetailScreen
- [ ] Add real-time price graph
- [ ] Create EditInvestmentSheet
- [ ] Implement manual price override

---

## File Structure (After V2 Implementation)

```
lib/
├── main.dart
├── models/
│   ├── market_data.dart
│   ├── investment.dart
│   └── currency.dart              (NEW)
├── providers/
│   ├── theme_provider.dart        (NEW)
│   ├── market_provider.dart       (NEW)
│   ├── portfolio_provider.dart    (NEW)
│   ├── currency_provider.dart     (NEW)
│   └── auth_provider.dart         (NEW)
├── screens/
│   ├── main_shell.dart            (NEW)
│   ├── welcome_screen.dart
│   ├── security_gate_screen.dart  (NEW)
│   ├── home_screen.dart           (RENAMED from dashboard)
│   ├── portfolio_screen.dart
│   ├── stock_detail_screen.dart   (NEW)
│   ├── settings_screen.dart
│   ├── profile_screen.dart
│   └── about_screen.dart
├── services/
│   ├── market_data_service.dart
│   ├── yahoo_finance_service.dart
│   ├── investment_service.dart
│   ├── gold_service.dart          (NEW)
│   ├── currency_service.dart      (NEW)
│   ├── pin_service.dart           (NEW)
│   ├── image_service.dart         (NEW)
│   └── preferences_service.dart
├── theme/
│   ├── app_theme.dart
│   └── dynamic_theme.dart         (NEW)
└── widgets/
    ├── statch_logo.dart
    ├── market_switcher.dart       (NEW)
    ├── stock_chip.dart            (NEW)
    ├── gold_card.dart
    ├── stock_card.dart
    ├── price_chart.dart
    ├── mini_chart.dart
    ├── edit_investment_sheet.dart (NEW)
    └── error_overlay.dart
```

---

## Performance Considerations

1. **10-Second Polling:**
   - Use `ChangeNotifier` with selective rebuilds
   - Compare previous vs new data before notifying
   - Use `const` widgets where possible

2. **Image Caching:**
   - Cache logo images with `cached_network_image`
   - Lazy load logos in lists

3. **Chart Optimization:**
   - Limit data points to visible range
   - Use `RepaintBoundary` for charts
   - Debounce touch interactions

4. **Memory Management:**
   - Dispose controllers properly
   - Cancel timers on dispose
   - Clear caches on low memory
