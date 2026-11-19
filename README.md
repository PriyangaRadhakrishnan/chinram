# 🌿 ChinRam — Agri-Estate, Farm & Crop Dryer Management System

[![Flutter](https://img.shields.io/badge/Flutter-v3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-v3.12+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Feature--First%20%7C%20Riverpod-teal)](#architecture--tech-stack)
[![Storage](https://img.shields.io/badge/Database-Hive%20NoSQL-orange)](https://docs.hivedb.dev/)
[![License](https://img.shields.io/badge/License-Proprietary-blue.svg)](#license)

**ChinRam** is an enterprise-grade, offline-first agricultural resource planning (ERP) mobile and cross-platform application. It is engineered specifically for plantation estates (coffee, pepper, cardamom, arecanut), mixed agricultural farms (crops, dairy, poultry), and commercial crop drying processing centers.

The app provides full visibility across worker attendance, automated payroll, inventory management (chemical & organic fertilizers), lumber harvesting ("Maravettu"), dairy operations, client drying batches, and real-time financial reporting with PDF/Excel export.

---

## 📑 Table of Contents

- [Core Highlights & Features](#-core-highlights--features)
- [Module Deep Dive](#-module-deep-dive)
  - [1. Authentication & Security](#1-authentication--security)
  - [2. Executive Dashboard](#2-executive-dashboard)
  - [3. Estate Management](#3-estate-management)
  - [4. Farm & Dairy Management](#4-farm--dairy-management)
  - [5. Commercial Dryer Operations](#5-commercial-dryer-operations)
  - [6. Financial Reports & Export Center](#6-financial-reports--export-center)
  - [7. Notifications & Settings](#7-notifications--settings)
- [Demo Credentials](#-demo-credentials)
- [Architecture & Tech Stack](#-architecture--tech-stack)
- [Project Directory Structure](#-project-directory-structure)
- [Getting Started & Reproduction Guide](#-getting-started--reproduction-guide)
  - [Prerequisites](#prerequisites)
  - [Step-by-Step Installation](#step-by-step-installation)
  - [Running the Application](#running-the-application)
- [Testing Suite](#-testing-suite)
- [Building the Production APK / Release](#-building-the-production-apk--release)
- [Design System & UI Guidelines](#-design-system--ui-guidelines)
- [Troubleshooting & FAQs](#-troubleshooting--faqs)

---

## ✨ Core Highlights & Features

- **📶 Offline-First Operation**: Built on fast, local **Hive NoSQL** storage. All records (attendance, expenses, harvest, customer visits) work seamlessly without an active internet connection.
- **🔄 Dual Operation Mode (Mock / API)**: Switch between offline demo data and remote backend REST APIs with a single configuration flag (`AppConfig.isMockMode`).
- **💰 Localized Accounting**: Native support for the Indian numbering system and currency (`₹` INR, e.g. `₹1,25,000.00`).
- **📱 Responsive Layout**: Adaptive layouts tailored for mobile phones, tablets, and desktop displays.
- **📊 Document Exporting**: Generate on-the-fly PDF summary statements and Excel spreadsheets (`.xlsx`) to share directly via WhatsApp, email, or cloud storage.
- **🛡️ Role-Based Workflows**: Custom views and permissions for Administrators, Estate Managers, Supervisors, and Field Workers.

---

## 🔍 Module Deep Dive

### 1. Authentication & Security
- **Role-Based Authentication**: Supports Administrator, Manager, Supervisor, and Worker roles.
- **Persistent Session State**: Powered by Riverpod and Hive (`auth_box`), automatically preserving login states between app launches.
- **Password Recovery**: Dedicated Forgot Password workflow.

### 2. Executive Dashboard
- **Financial Snapshot**: Real-time summary cards for Total Revenue, Total Operating Expenses, and Net Margin.
- **Quick Actions**: One-tap access to record daily attendance, log harvest sales, register dryer visits, or generate weekly reports.
- **Recent Activities Feed**: Consolidated timeline of activities across Estate, Farm, and Dryer units.

### 3. Estate Management
Designed for large-scale agricultural plantations:
- **Produce Income**: Track harvest yields, unit prices, buyers, and payments categorized by crop type (Coffee Arabica/Robusta, Pepper, Cardamom, Arecanut).
- **Worker Registry**: Maintain personnel records, emergency contacts, roles, and joining dates.
- **Daily Attendance**: Mark worker attendance (*Present*, *Half-Day*, *Absent*) with date picker and shift notes.
- **Configurable Salary Engine**:
  - Flexible wage configurations (daily wage rates, piece rates, bonus incentives, and statutory deductions).
  - Automated weekly and monthly salary calculation.
  - Dedicated **Manager Salary** ledger and approval flow.
- **Operational & Weekly Expenses**: Track fuel, equipment repairs, transport, utilities, and field supplies.
- **Fertilizer Management (Two-Tier)**:
  - *Chemical Fertilizers*: Track purchases, stock balances, batch lots, and per-acre application rates.
  - *Organic Fertilizers*: Track compost, bio-manure procurement, and distribution across plantation sectors.
- **Tree Count Ledger**: Plot-wise census of trees, health status, replant dates, and productivity metrics.
- **Tree Cutting ("Maravettu")**: Record timber sales, wood species, log/cubic-feet measurements, buyer details, and revenue.

### 4. Farm & Dairy Management
Tailored for livestock, dairy, poultry, and crop-farming operations:
- **Farm Income Ledger**: Log sales of raw milk, cattle, livestock, poultry, and organic manure.
- **Categorized Farm Expenses**: Feed purchases, veterinary medical bills, vaccine schedules, shed maintenance, and fuel.
- **Dedicated Milk Production Module**:
  - Daily yield monitoring (morning & evening shifts).
  - Fat/SNF quality metrics, cattle feed cost tracking, and refrigeration/delivery logs.
- **Farm Fertilizer & Compost Tracking**: Purchase tracking, compost pit maturation, and internal usage.
- **Farm Labor & Payroll**: Farm-specific worker wages, overtime calculations, and advances.
- **Farm Financial Analytics**: Visual distribution charts and monthly profit-and-loss summaries.

### 5. Commercial Dryer Operations
For commercial mechanical drying operations (e.g. coffee cherry/parchment drying):
- **Customer Directory**: Centralized directory of coffee farmers, growers, and trade agents.
- **Drying Visits & Batches**:
  - Input batch weight (kg / quintal) and initial moisture percentage (e.g. 50%).
  - Number of bags, drying hours, machine unit, and final target moisture (e.g. 11%).
- **Automated Cost Calculator**: Real-time bill estimation based on moisture reduction, weight, or bag count.
- **Dryer Expenses**: Log biomass, firewood, diesel, electricity power units, and machine maintenance expenses.
- **Customer Ledger & History**: Track completed vs pending drying batches and payment balances.

### 6. Financial Reports & Export Center
- **Cross-Domain Reporting**: Aggregate financial health across Estate, Farm, and Dryer units.
- **Flexible Date Filtering**: View metrics for *Today*, *This Week*, *This Month*, *Financial Year*, or a *Custom Date Range*.
- **Exporting**:
  - **PDF Export**: Clean, printable financial statements and wage slips generated via the `pdf` library.
  - **Excel Export**: Detailed spreadsheet workbooks (`.xlsx`) generated via the `excel` package.
  - **Share Integration**: Instant distribution via WhatsApp, email, or device storage via `share_plus`.

### 7. Notifications & Settings
- **Notification Inbox**: System reminders for low fertilizer inventory, pending salary disbursements, and maintenance schedules.
- **Settings**: App preferences, local data cache reset, currency preferences, and theme configuration.

---

## 🔑 Demo Credentials

When running the application with `AppConfig.isMockMode = true`, you can sign in using any of the following pre-configured mock credentials:

| Role | Email | Password | Access Level |
| :--- | :--- | :--- | :--- |
| **Administrator** | `admin@chinram.com` | `Admin@123` | Full access to all modules, configurations, and exports |
| **Manager** | `manager@chinram.com` | `Manager@123` | Estate, Farm, and Dryer operations, worker attendance, and reports |
| **Supervisor** | `supervisor@chinram.com` | `Supervisor@123` | Daily attendance, stock usage, and customer visit entries |
| **Worker** | `worker@chinram.com` | `Worker@123` | Basic profile, personal attendance, and wage slip review |

---

## 🏗️ Architecture & Tech Stack

ChinRam adheres to a **Feature-First Architecture** with strict separation of concerns:

```
UI Layer (Screens & Widgets) ──► Providers (Riverpod State) ──► Repositories (Interface) ──► Data Sources (Hive / API)
```

### Technology Highlights
- **Framework**: [Flutter](https://flutter.dev) (SDK `^3.12.2` / Flutter 3.x)
- **Language**: [Dart](https://dart.dev)
- **State Management**: [Riverpod 3.x](https://riverpod.dev) (`flutter_riverpod: ^3.3.2`)
- **Routing & Deep Linking**: [GoRouter 17.x](https://pub.dev/packages/go_router) (`go_router: ^17.3.0`)
- **Local Storage / Offline Cache**: [Hive](https://docs.hivedb.dev/) (`hive: ^2.2.3`, `hive_flutter: ^1.1.0`)
- **Document & Data Generation**:
  - PDF: [`pdf: ^3.12.0`](https://pub.dev/packages/pdf)
  - Excel: [`excel: ^4.0.6`](https://pub.dev/packages/excel)
  - File Storage: [`path_provider: ^2.1.6`](https://pub.dev/packages/path_provider)
  - Native Sharing: [`share_plus: ^13.2.0`](https://pub.dev/packages/share_plus)
- **Design System**: Material 3 theme with Google Fonts (*Plus Jakarta Sans*).

---

## 📂 Project Directory Structure

```text
chinram_app/
├── android/                        # Android native configuration & Gradle scripts
├── ios/                            # iOS native configuration & Podfile
├── web/                            # Web platform support assets
├── windows/                        # Windows native desktop support
├── linux/                          # Linux native desktop support
├── macos/                          # macOS native desktop support
├── lib/
│   ├── main.dart                   # Application entrypoint & Hive initialization
│   ├── core/
│   │   ├── config/                 # Environment switches (AppConfig.isMockMode)
│   │   ├── theme/                  # Brand colors (AppColors) & Material 3 theme
│   │   └── utils/                  # Currency formatting (INR ₹), responsive helpers
│   ├── features/
│   │   ├── authentication/         # Login, forgot password, auth providers & repos
│   │   ├── dashboard/              # Executive dashboard shell, stat cards, metrics
│   │   ├── estate/                 # Income, workers, attendance, salary, fertilizers, trees
│   │   │   ├── models/             # Domain data models (Workers, Salary, Attendance, etc.)
│   │   │   ├── providers/          # Riverpod state notifiers
│   │   │   ├── repositories/       # Hive & API repository implementations
│   │   │   ├── screens/            # Estate screens, forms, history & detail views
│   │   │   ├── services/           # Business logic & calculation engines
│   │   │   └── widgets/            # Reusable estate UI components
│   │   ├── farm/                   # Farm income, expenses, dairy/milk, compost, wages
│   │   │   ├── models/
│   │   │   ├── providers/
│   │   │   ├── repositories/
│   │   │   ├── screens/
│   │   │   └── services/
│   │   ├── dryer/                  # Dryer customer profiles, batches, expenses, calculator
│   │   │   ├── models/
│   │   │   ├── providers/
│   │   │   ├── repositories/
│   │   │   ├── screens/
│   │   │   ├── services/
│   │   │   └── utils/
│   │   ├── reports/                # Cross-domain financial reporting & export engines
│   │   ├── notifications/          # Alert system & notifications feed
│   │   └── settings/               # App preferences & profile management
│   ├── routes/
│   │   └── app_router.dart         # GoRouter path definitions & navigation tree
│   └── shared/
│       ├── dialogs/                # Confirmation, delete & alert dialogs
│       ├── extensions/             # BuildContext & responsive extensions
│       ├── models/                 # Shared data models (UserModel, etc.)
│       └── widgets/                # Buttons, custom text fields, cards, empty states
├── test/
│   ├── widget_test.dart            # Smoke tests
│   └── features/                   # Comprehensive feature & persistence test suites
│       ├── dryer/                  # Dryer calculation, widget & persistence tests
│       ├── estate/                 # Attendance, salary, income, fertilizer tests
│       └── farm/                   # Farm income, expense, fertilizer, salary tests
├── pubspec.yaml                    # Project dependencies & asset configuration
└── README.md                       # Complete documentation
```

---

## 🚀 Getting Started & Reproduction Guide

Follow these instructions to replicate and run this project from scratch on any machine.

### Prerequisites

Ensure you have the following installed on your development workstation:
1. **Flutter SDK**: Version `3.22.x` or later (includes Dart SDK `^3.12.2`).
   ```bash
   flutter --version
   ```
2. **Git**: For version control.
3. **IDE**: [Android Studio](https://developer.android.com/studio) or [Visual Studio Code](https://code.visualstudio.com/) with Flutter & Dart extensions.
4. **Android SDK & Build Tools**: (Required for Android device/emulator testing)
   - Java Development Kit (JDK 17 recommended).
   - Android SDK Platform 34 / 35.

### Step-by-Step Installation

#### 1. Clone the Repository
```bash
git clone https://github.com/PriyangaRadhakrishnan/chinram.git
cd chinram
```

#### 2. Install Project Dependencies
Run `flutter pub get` to download and link all required packages:
```bash
flutter pub get
```

#### 3. Verify Flutter Environment Health
Ensure your Flutter environment has no missing components:
```bash
flutter doctor
```

#### 4. Configure Application Environment
Open [`lib/core/config/app_config.dart`](file:///lib/core/config/app_config.dart):
```dart
class AppConfig {
  AppConfig._();

  // Set to `true` to use built-in offline Hive storage and demo users.
  // Set to `false` when connecting to live REST API endpoints.
  static const bool isMockMode = true;
}
```

---

### Running the Application

Connect an Android device (with USB debugging enabled) or launch an Android Virtual Device (AVD) / iOS Simulator / Chrome:

#### Run on Connected Device
```bash
flutter run
```

#### Run Specifically on Chrome (Web)
```bash
flutter run -d chrome
```

#### Run Specifically on Windows Desktop
```bash
flutter run -d windows
```

Sign in with `admin@chinram.com` / `Admin@123` to access all modules.

---

## 🧪 Testing Suite

ChinRam includes unit tests, widget tests, and offline Hive persistence tests covering all business-critical operations:

| Test Group | Coverage Areas |
| :--- | :--- |
| **Estate Module** | Worker attendance, salary configuration & calculation, tree counts, "maravettu" timber logging, fertilizer ledger |
| **Farm Module** | Farm income/expense categories, milk yield calculations, farm worker wages, compost logs |
| **Dryer Module** | Batch moisture calculator, customer ledgers, drying expense tracking, Hive persistence |
| **Smoke & Widgets**| UI renders, button triggers, router navigation, responsive breakpoints |

### Execute All Tests
```bash
flutter test
```

### Run a Specific Test Suite
```bash
# Test Estate Attendance
flutter test test/features/estate/attendance_test.dart

# Test Dryer Persistence
flutter test test/features/dryer/dryer_service_persistence_test.dart

# Test Farm Income
flutter test test/features/farm/farm_income_test.dart
```

---

## 📦 Building the Production APK / Release

To build production-ready installable binaries:

### Build Android Release APK
```bash
flutter build apk --release
```
- **Generated APK Output Location**:
  ```text
  build/app/outputs/flutter-apk/app-release.apk
  ```
- **Approximate Binary Size**: ~60 MB (self-contained with all native architectures `arm64-v8a`, `armeabi-v7a`, `x86_64`).

### Build Split APKs (Optimized per CPU architecture)
To minimize download sizes for end users:
```bash
flutter build apk --split-per-abi
```

### Build Google Play Android App Bundle (AAB)
```bash
flutter build appbundle --release
```
- Output location: `build/app/outputs/bundle/release/app-release.aab`

---

## 🎨 Design System & UI Guidelines

The ChinRam visual theme is crafted with an earthy, organic palette reflecting agriculture and coffee estates:

- **Primary**: `AppColors.primary` (`#6B4F3A` — *Coffee Brown*)
- **Secondary**: `AppColors.secondary` (`#8A9A5B` — *Olive Green*)
- **Accent**: `AppColors.accent` (`#C98A3D` — *Harvest Gold*)
- **Background**: `AppColors.background` (`#FAF8F4` — *Warm Parchment*)
- **Surface**: `AppColors.surface` (`#FFFFFF` — *Crisp White*)
- **Typography**: [Plus Jakarta Sans](https://fonts.google.com/specimen/Plus+Jakarta+Sans) via `google_fonts`

All numbers representing monetary values should use the shared utility:
```dart
import 'package:chinram_app/core/utils/currency_formatter.dart';

// Example: formatINR(150000) -> "₹1,50,000.00"
final formatted = formatINR(totalRevenue);
```

---

## ❓ Troubleshooting & FAQs

### 1. `HiveError: Box not found` or initialization issues
- Ensure `await Hive.initFlutter();` is called before opening any boxes inside `main.dart`.
- When switching between major schema changes, clear app data or uninstall the debug app to reset local Hive boxes.

### 2. Gradle build issues on Android
- If encountering Gradle build caching issues, clean and re-fetch dependencies:
  ```bash
  flutter clean
  flutter pub get
  cd android && ./gradlew clean && cd ..
  flutter build apk
  ```

### 3. Font loading when offline
- `google_fonts` automatically downloads fonts on first run. For full air-gapped offline use, bundle font assets in `pubspec.yaml` under `assets/fonts/`.

---

## 📄 License & Maintainer

- **Developer**: Priyanga Radhakrishnan
- **Repository**: [github.com/PriyangaRadhakrishnan/chinram](https://github.com/PriyangaRadhakrishnan/chinram)
- **Status**: Private Enterprise Project. All rights reserved.
