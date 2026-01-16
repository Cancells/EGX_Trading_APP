# Statch App Upgrade Plan

## Overview
Upgrading the Statch investment tracking app with Welcome Screen, real-time Yahoo Finance data, Investment Calculator, and enhanced logo design.

---

## Task 1: UI & Navigation

### 1.1 Welcome Screen
- **File:** `lib/screens/welcome_screen.dart`
- **Features:**
  - Full-screen stunning design with gradient background
  - Animated logo with fade-in + scale animation
  - Tagline with staggered text animation
  - "Get Started" button with glow effect
  - Check if first launch → show welcome, else skip to dashboard
  - Store `hasSeenWelcome` in preferences

### 1.2 Profile Navigation Fix
- **File:** `lib/screens/profile_screen.dart`
- **Change:** After successful save, call `Navigator.pop(context)` to return to dashboard immediately

---

## Task 2: Real-time Data (Yahoo Finance Integration)

### 2.1 Yahoo Finance Service
- **File:** `lib/services/yahoo_finance_service.dart`
- **Approach:** Use Yahoo Finance HTTP API (no Python backend needed)
- **Endpoints:**
  - Quote: `https://query1.finance.yahoo.com/v8/finance/chart/{symbol}`
  - Historical: Same endpoint with `period1` and `period2` params
- **Egyptian Symbols:**
  - EGX 30: `^EGX30` (index)
  - COMI: `COMI.CA` (Commercial International Bank)
  - TMGH: `TMGH.CA` (Talaat Mostafa)
  - ETEL: `ETEL.CA` (Telecom Egypt)
  - FWRY: `FWRY.CA` (Fawry)
- **Gold Symbols:**
  - Gold Spot: `GC=F` (futures) or `XAUUSD=X`

### 2.2 Market Data Provider (Riverpod)
- **File:** `lib/providers/market_provider.dart`
- **Features:**
  - StateNotifier for market data state
  - Timer-based polling every 10 seconds
  - Efficient UI updates without full rebuilds
  - Error handling with retry logic

### 2.3 Update Market Data Service
- **File:** `lib/services/market_data_service.dart`
- **Changes:**
  - Keep mock data as fallback
  - Add toggle between mock/live data
  - Integrate Yahoo Finance service

---

## Task 3: Investment Calculator

### 3.1 Investment Model
- **File:** `lib/models/investment.dart`
- **Fields:**
  - `id`: Unique identifier
  - `symbol`: Ticker symbol
  - `name`: Company name
  - `quantity`: Number of shares
  - `purchaseDate`: Date of purchase
  - `purchasePrice`: Historical price at purchase
  - `currentPrice`: Live price
  - `profitLoss`: Calculated P/L

### 3.2 Investment Service
- **File:** `lib/services/investment_service.dart`
- **Features:**
  - CRUD operations for investments
  - Persist to SharedPreferences (JSON)
  - Calculate P/L: `(currentPrice - purchasePrice) * quantity`

### 3.3 Add Investment Screen
- **File:** `lib/screens/add_investment_screen.dart`
- **Features:**
  - Form with ticker search/autocomplete
  - Quantity input
  - Date picker for purchase date
  - Auto-fetch historical price
  - Validation & save

### 3.4 Portfolio Screen
- **File:** `lib/screens/portfolio_screen.dart`
- **Features:**
  - List of investments with live P/L
  - Total portfolio value
  - Total P/L summary
  - Swipe to delete

---

## Task 4: Visual Design (Enhanced Logo)

### 4.1 Enhanced Logo
- **File:** `lib/widgets/statch_logo.dart`
- **Theme:** "Financial Growth"
- **Colors:**
  - Primary: Emerald Green (#00C805 / #10B981)
  - Secondary: Deep Charcoal (#1F2937)
- **Design:**
  - Growth chart arrow motif
  - Modern geometric style
  - Gradient fills
  - Glow effects for dark mode

---

## Implementation Order

1. **Phase 1: Foundation**
   - [x] Create PLAN.md
   - [x] Add `http` package to pubspec.yaml
   - [x] Add `provider` package

2. **Phase 2: Welcome Screen**
   - [x] Create WelcomeScreen with stunning fade-in animations
   - [x] Update main.dart routing
   - [x] Add hasSeenWelcome to PreferencesService

3. **Phase 3: Profile Fix**
   - [x] Update _saveProfile() to pop after save

4. **Phase 4: Yahoo Finance Integration**
   - [x] Create YahooFinanceService
   - [x] Support EGX symbols (.CA suffix)
   - [x] Support Gold symbols (GC=F, XAUUSD=X)
   - [x] Historical price fetching for specific dates

5. **Phase 5: Investment Calculator**
   - [x] Create Investment model with P/L calculations
   - [x] Create InvestmentService with 10-second polling
   - [x] Create AddInvestmentScreen with symbol search
   - [x] Create PortfolioScreen with live P/L
   - [x] Add navigation to dashboard menu

6. **Phase 6: Logo Enhancement**
   - [x] Redesign StatchLogo with gradients
   - [x] Add glow effects
   - [x] Add draw animation variant

---

## File Structure (After Implementation)

```
lib/
├── main.dart
├── models/
│   ├── market_data.dart
│   └── investment.dart
├── providers/
│   └── market_provider.dart
├── screens/
│   ├── welcome_screen.dart      (NEW)
│   ├── dashboard_screen.dart
│   ├── profile_screen.dart      (MODIFIED)
│   ├── settings_screen.dart
│   ├── about_screen.dart
│   ├── portfolio_screen.dart    (NEW)
│   └── add_investment_screen.dart (NEW)
├── services/
│   ├── market_data_service.dart (MODIFIED)
│   ├── yahoo_finance_service.dart (NEW)
│   ├── investment_service.dart  (NEW)
│   └── preferences_service.dart (MODIFIED)
├── theme/
│   └── app_theme.dart
└── widgets/
    ├── statch_logo.dart         (ENHANCED)
    ├── error_overlay.dart
    ├── gold_card.dart
    ├── mini_chart.dart
    ├── price_chart.dart
    └── stock_card.dart
```

---

## Dependencies to Add

```yaml
dependencies:
  http: ^1.2.0          # HTTP requests for Yahoo Finance
  provider: ^6.1.1      # Simple state management
```

---

## Notes

- Yahoo Finance API is unofficial but widely used
- EGX symbols use `.CA` suffix (Cairo exchange)
- Gold tracked via futures/spot symbols
- Keep mock data as fallback for offline/demo mode
- 10-second polling interval balances freshness vs. API limits
