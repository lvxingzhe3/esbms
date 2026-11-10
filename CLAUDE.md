# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Sinota esBMS is a Flutter mobile application for Battery Management System (BMS) monitoring and control. The app connects to BMS devices via Bluetooth to display real-time battery data including voltage, current, temperature, and cell information.

**Tech Stack:**

- Flutter 3.32.4 / Dart 3.8.1
- State Management: Riverpod 2.6.1
- Navigation: go_router 16.2.0
- Bluetooth: flutter_blue_plus 2.0.0
- MQTT: mqtt5_client 4.14.0
- Auth: AWS Amplify (Cognito)
- Internationalization: flutter_intl (zh_CN primary, English supported)

## Development Commands

### Build & Run

```bash
# Get dependencies
flutter pub get

# Run on connected device
flutter run

# Build for specific platforms
flutter build apk                    # Android APK
flutter build appbundle             # Android App Bundle
flutter build ios                   # iOS
flutter build macos                 # macOS

# Clean build artifacts
flutter clean
```

### Testing & Analysis

```bash
# Run linter
flutter analyze

# Run tests
flutter test

# Run specific test file
flutter test test/widget_test.dart
```

### Code Generation

```bash
# Generate launcher icons (configured in pubspec.yaml)
flutter pub run flutter_launcher_icons

# Generate localization files (managed by flutter_intl)
# Typically auto-generated when .arb files are modified
flutter pub run intl_utils:generate
```

### Android Signing

The project uses release signing for Android builds. Ensure `android/key.properties` exists with:

```
storePassword=<password>
keyPassword=<password>
keyAlias=<alias>
storeFile=<path-to-keystore>
```

## Architecture

### State Management (Riverpod)

The app recently migrated from Provider to Riverpod. All state is managed through Riverpod providers:

- **`app_stateProvider`** (`lib/state/app_state.dart`): Manages bottom tab navigation index
- **`bleStateProvider`** (`lib/state/bluetooth_state.dart`): Manages Bluetooth connection state and real-time BMS data parsing

State pattern: Use `NotifierProvider` for mutable state, expose immutable data classes.

### Navigation (go_router)

Routes are centrally defined in `lib/helper/routes.dart`. Structure:

```
/ (splash) → /home → /home/firmware
                  → /home/bluetooth
                  → /home/battery-cell
           → /privacy
```

Use named routes for navigation:

```dart
context.go('/home');
context.goNamed(AppRouter.bluetooth);
```

### Bluetooth Data Protocol

**Key Implementation:** `lib/state/bluetooth_state.dart`

BMS devices send data over Bluetooth in ASCII chunks with custom protocol:

```
{key: data, value: [{name: xxx, value: 1, multiple: 10, unit: mV}]}
```

The `BleNotifier` class handles:

1. Chunk assembly (data arrives in multiple packets)
2. JSON-like string parsing (non-standard format with unquoted keys)
3. Special calculations for current (two's complement) and temperature (offset formula)

**Current Calculation:**

- Values < 32768: charging current (positive)
- Values >= 32768: discharging current = -(65535 - value) \* multiple

**Temperature Calculation:**

- Temperature (°C) = (value - 2730) / 10

### Data Models

**`BluetoothModel`** (`lib/model/bluetooth.dart`):

- Core model for all BMS data
- Provides named accessors for specific metrics: `bat`, `current`, `power`, `soc`, `cycle`, etc.
- Contains `cells_voltage` list for individual cell data
- `finalDisplayValue` handles unit conversion and formatting

**`DeviceInfoModel`** (`lib/model/device.dart`):

- Generic device information display model
- Used for structured device detail views

### UI Structure

```
lib/ui/
├── page/
│   ├── splash/          # App launch screen
│   ├── home/            # Main container with bottom navigation
│   │   └── widgets/     # Bottom tab bar widget
│   ├── profile/         # Device data display page (tab 0)
│   ├── settings/        # Settings page (tab 1)
│   ├── user/            # User profile page (tab 2)
│   ├── device/          # Device-specific pages (bluetooth, firmware, battery cells)
│   └── bluetooth/       # Bluetooth scanning & connection
├── theme/               # App-wide theming (colors, text styles, custom icons)
└── widgets/             # Reusable widgets (custom buttons, loaders, etc.)
```

**Main Flow:**

1. SplashPage → HomePage (with bottom tabs)
2. HomePage displays ProfilePage/SettingsPage/UserPage based on tab index
3. ProfilePage shows real-time BMS data from `bleStateProvider`
4. Bluetooth scanning/connection handled in bluetooth/ pages

### Theming

- Custom theme defined in `lib/ui/theme/theme.dart`
- Uses Google Fonts (Mulish) + custom HelveticaNeue font family
- Custom icon font: BmsIcon (`lib/ui/theme/app_icons.dart`)
- Light theme only (LightColor in `lib/ui/theme/color/light_color.dart`)

### Localization

- Primary locale: zh_CN (Chinese)
- Secondary: en_US (English)
- Generated files in `lib/generated/l10n.dart`
- String resources in `lib/l10n/*.arb`
- Access via `S.of(context).stringKey` or `S.current.stringKey`

## Important Notes

### Bluetooth Connection Lifecycle

When setting up Bluetooth characteristic subscription:

1. Call `setCharacteristic()` with characteristic and device
2. Notifier automatically subscribes to value changes
3. Subscription is cancelled when device disconnects (via `cancelWhenDisconnected`)
4. Always reset state to null when disconnecting

### Widget Patterns

- Use `ConsumerWidget` (Riverpod) for widgets that read state
- Access state: `ref.watch(provider)` for reactive updates
- Mutate state: `ref.read(provider.notifier).method()`

### Assets

- Launch logo: `assets/images/launch_logo.png`
- OTA firmware: `assets/ota/ota_v1.0.0.bin`
- Custom fonts in `assets/fonts/`

### Git Workflow

Current branch: `feat/wifi` (add WiFi connectivity feature)
Main branch: `main`
Recent work includes:

- Migration from Provider to Riverpod
- APK packaging setup
- Application name refactoring

## Common Patterns

### Reading BMS Data

```dart
// In a ConsumerWidget
final bleState = ref.watch(bleStateProvider);
final batteryVoltage = bleState.bleModel.bat.finalDisplayValue;
final cellVoltages = bleState.bleModel.cells_voltage;
```

### Navigation

```dart
// Push named route
context.goNamed(AppRouter.firmware);

// Pop back
context.pop();

// Replace with new route
context.go('/home');
```

### Internationalization

```dart
// In build method with BuildContext
Text(S.of(context).title)

// Outside build (static)
String label = S.current.times;
```
