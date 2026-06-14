import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/tv_device_info.dart';
import '../../domain/models/remote_command.dart';
import '../../domain/models/time_restriction.dart';
import '../../domain/interfaces/tv_controller.dart';
import '../../data/manufacturers/panasonic/panasonic_controller.dart';
import '../../core/discovery/ssdp_discovery.dart';
import '../../core/discovery/wake_on_lan.dart';

/// Creates the appropriate [TvController] for a given brand.
/// Override this provider in tests to inject mock controllers.
final controllerFactoryProvider = Provider<TvController Function(TvBrand)>((ref) {
  return _createController;
});

TvController _createController(TvBrand brand) {
  switch (brand) {
    case TvBrand.panasonic:
      return PanasonicController();
    default:
      throw UnimplementedError('TV brand $brand is not yet supported');
  }
}

/// Stored MAC address for Wake-on-LAN.
final wolMacAddressProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('wol_mac_address');
});

/// Time restriction settings for parental controls.
final timeRestrictionProvider = FutureProvider<TimeRestriction>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final json = prefs.getString('time_restriction');
  if (json == null) return TimeRestriction.defaults();
  try {
    return TimeRestriction.fromJson(
        jsonDecode(json) as Map<String, dynamic>);
  } catch (_) {
    return TimeRestriction.defaults();
  }
});

/// Saves time restriction settings.
final saveTimeRestrictionProvider =
    Provider<Future<void> Function(TimeRestriction)>((ref) {
  return (TimeRestriction restriction) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'time_restriction', jsonEncode(restriction.toJson()));
    ref.invalidate(timeRestrictionProvider);
  };
});

/// Manages the list of saved devices.
final savedDevicesProvider =
    FutureProvider<List<TvDeviceInfo>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final json = prefs.getStringList('saved_devices') ?? [];
  return json
      .map((e) => TvDeviceInfo.fromJson(jsonDecode(e) as Map<String, dynamic>))
      .toList();
});

/// Currently connected TV device info.
final currentDeviceProvider = StateProvider<TvDeviceInfo?>((ref) => null);

/// The active TV controller (manufacturer-specific).
final tvControllerProvider = StateProvider<TvController?>((ref) => null);

/// Whether we're currently connected.
final isConnectedProvider = Provider<bool>((ref) {
  final controller = ref.watch(tvControllerProvider);
  return controller?.isConnected ?? false;
});


/// Whether a network scan is currently in progress.
final isScanningProvider = StateProvider<bool>((ref) => false);

/// Discovered devices from the last scan.
final discoveredDevicesProvider = StateProvider<List<TvDeviceInfo>>((ref) => []);

/// Scans the network for TVs.
final scanNetworkProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    if (ref.read(isScanningProvider)) return; // Already scanning
    ref.read(isScanningProvider.notifier).state = true;

    try {
      final devices = await SsdpDiscovery.discover();
      ref.read(discoveredDevicesProvider.notifier).state = devices;
    } finally {
      ref.read(isScanningProvider.notifier).state = false;
    }
  };
});

/// The device currently being connected to (null if idle).
final connectingDeviceProvider = StateProvider<TvDeviceInfo?>((ref) => null);

/// Connects to a TV device.
/// Returns an async function so the connection logic is not a provider itself,
/// avoiding Riverpod's restriction on modifying other providers during build.
final connectToDeviceProvider = Provider<Future<void> Function(TvDeviceInfo)>((
  ref,
) {
  return (TvDeviceInfo device) async {
    ref.read(connectingDeviceProvider.notifier).state = device;

    try {
      final factory = ref.read(controllerFactoryProvider);
      final controller = factory(device.brand);
      final success = await controller.connect(device);
      if (success) {
        ref.read(currentDeviceProvider.notifier).state = device;
        ref.read(tvControllerProvider.notifier).state = controller;

        // Persist the device, preserving any custom name from an existing save
        final prefs = await SharedPreferences.getInstance();
        final savedJsons = prefs.getStringList('saved_devices') ?? [];
        final savedDevices = savedJsons
            .map((e) => TvDeviceInfo.fromJson(
                jsonDecode(e) as Map<String, dynamic>))
            .toList();

        // Remove any existing device with the same IP:Port
        final existingIndex = savedDevices.indexWhere(
          (d) => d.ipAddress == device.ipAddress && d.port == device.port,
        );
        TvDeviceInfo toSave;
        if (existingIndex != -1) {
          // Preserve the user's custom name
          toSave = device.copyWith(name: savedDevices[existingIndex].name);
          savedDevices.removeAt(existingIndex);
        } else {
          toSave = device;
        }
        savedDevices.insert(0, toSave);

        final updatedJsons =
            savedDevices.map((d) => jsonEncode(d.toJson())).toList();
        await prefs.setStringList('saved_devices', updatedJsons);

        final deviceJson = jsonEncode(toSave.toJson());

        // Remember last connected device for auto-reconnect
        await prefs.setString('last_connected', deviceJson);

        ref.invalidate(savedDevicesProvider);
      } else {
        throw Exception('Failed to connect to ${device.name}');
      }
    } finally {
      ref.read(connectingDeviceProvider.notifier).state = null;
    }
  };
});

/// Disconnects from the current TV.
final disconnectProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final controller = ref.read(tvControllerProvider);
    await controller?.disconnect();
    ref.read(currentDeviceProvider.notifier).state = null;
    ref.read(tvControllerProvider.notifier).state = null;
  };
});

/// Sends a remote command to the connected TV.
/// Returns null on success, or an error message string on failure.
final sendCommandProvider = Provider<Future<String?> Function(RemoteCommand)>((
  ref,
) {
  return (RemoteCommand command) async {
    try {
      final controller = ref.read(tvControllerProvider);
      if (controller == null) {
        return 'Not connected to a TV';
      }
      // Time restriction gate: block all commands except power
      final restriction = ref.read(timeRestrictionProvider).valueOrNull;
      if (restriction != null && !restriction.isAllowed(DateTime.now())) {
        if (command != RemoteCommand.power) {
          return 'TV viewing is restricted at this time';
        }
      }
      await controller.sendCommand(command);
      return null; // success
    } catch (e) {
      // Detect disconnection
      ref.read(tvControllerProvider)?.disconnect();
      ref.read(tvControllerProvider.notifier).state = null;
      ref.read(isConnectedProvider);
      return 'Command failed: $e';
    }
  };
});

/// Sends a Wake-on-LAN packet to a device.
final wakeOnLanProvider = Provider<Future<void> Function(TvDeviceInfo)>((
  ref,
) {
  return (TvDeviceInfo device) async {
    await _sendWol(ref, device);
  };
});

Future<void> _sendWol(Ref ref, TvDeviceInfo device) async {
  final macAddress = ref.read(wolMacAddressProvider).value ?? '';
  if (macAddress.isEmpty) return; // No MAC configured, skip WOL

  await WakeOnLan.wake(macAddress);
}

/// Rename a saved device.
final renameDeviceProvider = Provider<Future<void> Function(TvDeviceInfo, String)>((
  ref,
) {
  return (TvDeviceInfo device, String newName) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_devices') ?? [];
    final oldJson = jsonEncode(device.toJson());
    final updated = device.copyWith(name: newName);
    final newJson = jsonEncode(updated.toJson());

    // Replace in saved list
    final index = saved.indexOf(oldJson);
    if (index != -1) {
      saved[index] = newJson;
    }
    await prefs.setStringList('saved_devices', saved);

    // Update last_connected if it matches the old device
    final lastConnected = prefs.getString('last_connected');
    if (lastConnected == oldJson) {
      await prefs.setString('last_connected', newJson);
    }

    // Update current device if connected to this TV
    if (ref.read(currentDeviceProvider)?.ipAddress == device.ipAddress &&
        ref.read(currentDeviceProvider)?.port == device.port) {
      ref.read(currentDeviceProvider.notifier).state = updated;
    }

    ref.invalidate(savedDevicesProvider);
  };
});

/// Delete a saved device.
final deleteDeviceProvider = Provider<Future<void> Function(TvDeviceInfo)>((
  ref,
) {
  return (TvDeviceInfo device) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_devices') ?? [];
    final deviceJson = jsonEncode(device.toJson());
    saved.remove(deviceJson);
    await prefs.setStringList('saved_devices', saved);
    ref.invalidate(savedDevicesProvider);
  };
});

/// Save the WOL MAC address.
final saveMacAddressProvider = Provider<Future<void> Function(String)>((
  ref,
) {
  return (String mac) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wol_mac_address', mac);
    ref.invalidate(wolMacAddressProvider);
  };
});
