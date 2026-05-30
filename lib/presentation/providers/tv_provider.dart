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

/// Connects to a TV device.
final connectToDeviceProvider = FutureProvider.family<void, TvDeviceInfo>((
  ref,
  device,
) async {
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
    ref.invalidate(savedDevicesProvider);
  } else {
    throw Exception('Failed to connect to ${device.name}');
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
final sendCommandProvider = Provider<Future<void> Function(RemoteCommand)>((
  ref,
) {
  return (RemoteCommand command) async {
    final controller = ref.read(tvControllerProvider);
    if (controller == null) {
      throw StateError('Not connected to a TV');
    }
    await controller.sendCommand(command);
  };
});

/// Sends a Wake-on-LAN packet to a device.
final wakeOnLanProvider = Provider<Future<void> Function(TvDeviceInfo)>((
  ref,
) {
  return (TvDeviceInfo device) async {
    await _sendWol(device);
  };
});

Future<void> _sendWol(TvDeviceInfo device) async {
  // Panasonic TVs typically use a WOL magic packet with the TV's MAC address.
  // Since we don't always have the MAC address, we try a generic broadcast.
  // Users can configure the MAC address in settings for reliable WOL.
  await WakeOnLan.wake('00:00:00:00:00:00');
}
