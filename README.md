# tv-remote

Multi-platform TV remote control app built with Flutter. Supports iOS, Android, macOS, and Web.

Currently supports **Panasonic Viera TVs** via NRC SOAP/XML protocol. Designed to easily add other manufacturers.

## Prerequisites

### All platforms

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.44+)
  ```bash
  brew install flutter
  ```

### macOS

- Xcode (full version, not just Command Line Tools)
  ```bash
  # Ensure xcode-select points to full Xcode
  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

  # Accept license (first time)
  sudo xcodebuild -runFirstLaunch
  ```
- [CocoaPods](https://cocoapods.org/)
  ```bash
  brew install cocoapods
  ```

### iOS

- Xcode (same as macOS)
- CocoaPods (same as macOS)

### Android

- [Android Studio](https://developer.android.com/studio) with Android SDK
- Set `ANDROID_HOME` environment variable

### Web

- No extra dependencies required. Runs in Chrome or any Chromium-based browser.

## Setup

```bash
# Clone the repository
git clone git@github.com:linzhengen/tv-remote.git
cd tv-remote

# Install Flutter dependencies
flutter pub get

# Install CocoaPods (macOS/iOS only)
cd macos && pod install && cd ..
cd ios && pod install && cd ..
```

## Run

```bash
# macOS
flutter run -d macos

# iOS (boot a simulator first)
open -a Simulator
flutter run

# Android
flutter run -d android

# Web
flutter run -d chrome
```

## Usage

1. **Ensure your TV has Network Remote Control enabled** in its settings menu.
2. Make sure your device and TV are on the **same local network**.
3. Open the app. It will scan for Panasonic TVs on the network using SSDP.
4. Alternatively, tap **+** to manually enter your TV's IP address.
5. Select your TV to connect and start controlling it.

## Supported Panasonic Commands

| Category | Commands |
|----------|----------|
| Power | Power |
| Volume | Vol+, Vol-, Mute |
| Channel | CH+, CH- |
| Navigation | Up, Down, Left, Right, OK, Back, Home |
| Numbers | 0-9 |
| Media | Play, Pause, Stop, Rew, FF, Skip Next, Skip Prev, Record |
| Input | Change Input |
| Menu | Menu, Guide, Info |
| Color | Red, Green, Blue, Yellow |
| Other | Subtitles, Aspect, Internet, Apps, Viera Link, Last View |

## Architecture

```
lib/
├── domain/                  # Interfaces & models (brand-agnostic)
│   ├── interfaces/          # TvController interface
│   └── models/              # TvDeviceInfo, RemoteCommand, layouts
├── data/manufacturers/      # Manufacturer-specific implementations
│   └── panasonic/           # Panasonic NRC SOAP/XML controller
├── core/                    # Cross-cutting utilities
│   ├── discovery/           # SSDP discovery, Wake-on-LAN
│   └── theme/               # App theme
└── presentation/            # UI layer (Riverpod + Flutter)
    ├── providers/           # State management
    ├── screens/             # Discovery, Remote, Settings
    └── widgets/             # D-Pad, Numpad, Volume, Media buttons
```

### Adding a new manufacturer

1. Create `lib/data/manufacturers/<brand>/<brand>_controller.dart` implementing `TvController`
2. Define command mappings
3. Add discovery logic (if brand-specific)
4. Register in `tv_provider.dart`

No changes needed to the domain or presentation layers.

## Verify

```bash
# Static analysis
flutter analyze

# Tests
flutter test
```
