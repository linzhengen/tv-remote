# AI Development Guide for TV Remote

This document is designed for AI coding assistants (like Gemini, Claude, etc.) and human developers to quickly understand the project layout, architecture, state management, protocols, and standard workflows for extending this TV Remote app.

---

## 🗺️ Project Architecture & Layout

The project follows a modified Clean Architecture pattern with distinct layers to separate business logic, UI, and hardware communication:

```
lib/
├── domain/                  # Brand-agnostic models & interfaces (Core Logic)
│   ├── interfaces/          # tv_controller.dart (Hardware abstraction)
│   └── models/              # tv_device_info.dart, remote_command.dart, remote_button_layout.dart
├── data/                    # Infrastructure / Implementation layer
│   └── manufacturers/       # Manufacturer-specific network controllers
│       └── panasonic/       # Panasonic SOAP/XML key controller
├── core/                    # Low-level cross-cutting concerns
│   ├── discovery/           # ssdp_discovery.dart (SSDP/Subnet scan), wake_on_lan.dart
│   └── theme/               # App UI styling
├── presentation/            # UI Layer (Flutter + Riverpod)
│   ├── providers/           # tv_provider.dart (State, Connection, Scanning)
│   ├── screens/             # DiscoveryScreen, RemoteScreen, SettingsScreen
│   └── widgets/             # ControlPad, RemoteButton, etc.
└── di/                      # Dependency Injection overrides (if any)
```

---

## 🛠️ Key Protocols & Implementations

### 1. Device Discovery (`lib/core/discovery/ssdp_discovery.dart`)
* **SSDP (UPnP)**: Broadcasts `M-SEARCH` requests on `239.255.255.250:1900` over UDP looking for Panasonic TVs.
  * *Note*: On iOS, SSDP utilizes native `Network.framework` via a Method Channel (`com.seion.tvRemote/ssdp_discovery`) to bypass the strict Multicast Entitlement requirement.
* **TCP Subnet Scanning (Fallback)**: If SSDP returns nothing (e.g., due to multicast-blocking routers), the app fetches the local IPv4 address and runs a fast TCP connect check on port `55000` (Panasonic's control port) across the `/24` subnet.

### 2. Network Controller Interface (`lib/domain/interfaces/tv_controller.dart`)
Any TV brand controller must implement the `TvController` interface:
```dart
abstract class TvController {
  Future<bool> connect(TvDeviceInfo device);
  Future<void> disconnect();
  Future<void> sendCommand(RemoteCommand command);
  Future<void> powerOn(TvDeviceInfo device);
  bool get isConnected;
}
```

### 3. Panasonic Controller (`lib/data/manufacturers/panasonic/panasonic_controller.dart`)
* Sends HTTP POST requests containing SOAP envelopes to `http://<IP>:55000/nrc/control_0`.
* Content-Type: `text/xml; charset="utf-8"`
* Header `SOAPACTION`: `"urn:panasonic-com:service:p00NetworkControl:1#X_SendKey"`
* Body envelope embeds the Viera Key Code (e.g., `NRC_CH_UP-ONOFF` for Channel Up).

### 4. Wake-on-LAN (`lib/core/discovery/wake_on_lan.dart`)
* Broadcasts UDP magic packets to wake TVs that are in low-power standby mode.

---

## 🚀 How to Add a New TV Brand (Step-by-Step)

To add support for a new brand (e.g., Samsung, Sony, LG):

### Step 1: Update Domain Models
1. Add the brand to `TvBrand` enum in [tv_device_info.dart](file:///Users/seion/self/tv-remote/lib/domain/models/tv_device_info.dart):
   ```dart
   enum TvBrand {
     panasonic,
     samsung,
     lg,
     sony,
   }
   ```

### Step 2: Implement the Brand Controller
1. Create a new directory and files: `lib/data/manufacturers/<brand>/`.
2. Create `<brand>_commands.dart` to map generic `RemoteCommand` values to brand-specific payloads (e.g. JSON strings or proprietary codes).
3. Create `<brand>_controller.dart` implementing `TvController`.
   * Implement connection check, XML/JSON request formatting, and WOL/power logic.

### Step 3: Register the Controller
1. Update `_createController` inside [tv_provider.dart](file:///Users/seion/self/tv-remote/lib/presentation/providers/tv_provider.dart):
   ```dart
   TvController _createController(TvBrand brand) {
     switch (brand) {
       case TvBrand.panasonic:
         return PanasonicController();
       case TvBrand.samsung:
         return SamsungController(); // Add your new controller here
       default:
         throw UnimplementedError('TV brand $brand is not yet supported');
     }
   }
   ```

### Step 4: Hook into Discovery (Optional but Recommended)
1. If the brand uses a specific UPnP Service Type (`ST`) or a different control port for detection, update [ssdp_discovery.dart](file:///Users/seion/self/tv-remote/lib/core/discovery/ssdp_discovery.dart):
   * Add the discovery search target string to the native SSDP search block.
   * Add a subnet scan fallback checking the target brand's default communication port.
   * Parse the brand signature inside `_parseSsdpResponse`.

### Step 5: Design Button Layout (Optional)
* If the remote control layout for this brand differs significantly, customize or map layouts in [remote_button_layout.dart](file:///Users/seion/self/tv-remote/lib/domain/models/remote_button_layout.dart).

---

## 🧪 Testing & Validation

Always run formatting and analysis commands to ensure code health before submitting changes:

```bash
# Format codebase
flutter format .

# Check for static analysis errors
flutter analyze

# Run unit and widget tests
flutter test
```

> [!IMPORTANT]
> When executing actions as an AI assistant, remember:
> * Keep all existing documentation/comments intact unless explicitly asked to modify them.
> * Avoid running `git commit` commands directly unless the user explicitly requests you to perform a commit.
