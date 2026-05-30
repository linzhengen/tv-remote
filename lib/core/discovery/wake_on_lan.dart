import 'dart:typed_data';
import 'dart:io';

/// Sends a Wake-on-LAN magic packet to wake a device from sleep.
class WakeOnLan {
  /// Broadcasts a magic packet to turn on the device with the given MAC address.
  ///
  /// On iOS, uses subnet-directed broadcast. On Web, this is a no-op.
  static Future<void> wake(String macAddress, {String? broadcastAddress}) async {
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
        bytes[6 + i * 6 + j] = int.parse(mac.substring(j * 2, j * 2 + 2), radix: 16);
      }
    }

    final address = broadcastAddress ?? '255.255.255.255';
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;
    socket.send(bytes, InternetAddress(address), 9);
    socket.close();
  }
}
