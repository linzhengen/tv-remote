import 'dart:io';

import 'package:flutter/foundation.dart';

/// Sends a Wake-on-LAN magic packet to wake a device from sleep.
class WakeOnLan {
  /// Broadcasts a magic packet to turn on the device with the given MAC address.
  ///
  /// On iOS, uses subnet-directed broadcast. On Web, this is a no-op.
  static Future<void> wake(
    String macAddress, {
    String? broadcastAddress,
    String? subnet,
  }) async {
    if (kIsWeb) return; // Raw sockets not available on web

    final mac = macAddress.replaceAll(RegExp(r'[:\-]'), '');
    if (mac.length != 12) {
      throw ArgumentError('Invalid MAC address: $macAddress');
    }

    final bytes = Uint8List(102);
    // 6 bytes of 0xFF
    for (var i = 0; i < 6; i++) {
      bytes[i] = 0xFF;
    }
    // MAC address repeated 16 times
    for (var i = 0; i < 16; i++) {
      for (var j = 0; j < 6; j++) {
        bytes[6 + i * 6 + j] =
            int.parse(mac.substring(j * 2, j * 2 + 2), radix: 16);
      }
    }

    // On iOS, use subnet broadcast if provided, else default
    final address = broadcastAddress ??
        (Platform.isIOS ? _getSubnetBroadcast(subnet) : '255.255.255.255') ??
        '255.255.255.255';

    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      socket.send(bytes, InternetAddress(address), 9);
    } finally {
      socket?.close();
    }
  }

  /// Derives the subnet broadcast address from a subnet string like "192.168.1".
  static String? _getSubnetBroadcast(String? subnet) {
    if (subnet == null || subnet.isEmpty) return null;
    // Expect format like "192.168.1" → broadcast is "192.168.1.255"
    return '$subnet.255';
  }
}
