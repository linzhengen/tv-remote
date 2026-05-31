import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/tv_device_info.dart';
import '../../domain/models/remote_command.dart';
import '../../domain/interfaces/tv_controller.dart';
import '../../data/manufacturers/panasonic/panasonic_controller.dart';
import '../../core/discovery/ssdp_discovery.dart';
import '../../core/discovery/wake_on_lan.dart';

/// Creates the appropriate [TvController] for a given brand.
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


/// Discover TVs on the network.
final discoveryProvider = FutureProvider<List<TvDeviceInfo>>((ref) async {
  return SsdpDiscovery.discover();
});

/// The device currently being connected to (null if idle).
final connectingDeviceProvider = StateProvider<TvDeviceInfo?>((ref) => null);

/// Connects to a TV device.
final connectToDeviceProvider = FutureProvider.family<void, TvDeviceInfo>((
  ref,
  device,
) async {
  // Set connecting state — OK here because this runs inside the Future,
  // not during another provider's synchronous build.
  // We use Future.microtask to defer the state change past the build phase.
  await Future<void>.delayed(Duration.zero);
  ref.read(connectingDeviceProvider.notifier).state = device;

  try {
    final controller = _createController(device.brand);
    final success = await controller.connect(device);
    if (success) {
      ref.read(currentDeviceProvider.notifier).state = device;
      ref.read(tvControllerProvider.notifier).state = controller;

      // Persist the device
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('saved_devices') ?? [];
      final deviceJson = jsonEncode(device.toJson());
      saved.remove(deviceJson);
      saved.insert(0, deviceJson);
      await prefs.setStringList('saved_devices', saved);

      // Remember last connected device for auto-reconnect
      await prefs.setString('last_connected', deviceJson);

      ref.invalidate(savedDevicesProvider);
    } else {
      throw Exception('Failed to connect to ${device.name}');
    }
  } finally {
    ref.read(connectingDeviceProvider.notifier).state = null;
  }
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
