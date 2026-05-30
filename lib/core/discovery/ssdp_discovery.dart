import 'dart:async';
import 'dart:io';

import '../../domain/models/tv_device_info.dart';

/// Discovers Panasonic TVs on the local network using SSDP (UPnP).
class SsdpDiscovery {
  static const _multicastAddress = '239.255.255.250';
  static const _port = 1900;
  static const _mx = 3; // seconds to wait for responses

  /// Searches for Panasonic Viera TVs via SSDP M-SEARCH.
  ///
  /// Returns a list of discovered [TvDeviceInfo] objects.
  static Future<List<TvDeviceInfo>> discover({Duration timeout = const Duration(seconds: 5)}) async {
    final devices = <TvDeviceInfo>{};

    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;
    socket.readEventsEnabled = true;

    final searchMessage = 'M-SEARCH * HTTP/1.1\r\n'
        'HOST: $_multicastAddress:$_port\r\n'
        'MAN: "ssdp:discover"\r\n'
        'MX: $_mx\r\n'
        'ST: urn:panasonic-com:service:p00NetworkControl:1\r\n'
        '\r\n';

    socket.send(
      searchMessage.codeUnits,
      InternetAddress(_multicastAddress),
      _port,
    );

    final completer = Completer<void>();
    Timer(timeout, () {
      if (!completer.isCompleted) completer.complete();
    });

    socket.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = socket.receive();
        if (datagram != null) {
          final data = String.fromCharCodes(datagram.data);
          final device = _parseSsdpResponse(data, datagram.address.address);
          if (device != null) {
            devices.add(device);
          }
        }
      }
      if (event == RawSocketEvent.closed && !completer.isCompleted) {
        completer.complete();
      }
    });

    await completer.future;
    socket.close();
    return devices.toList();
  }

  static TvDeviceInfo? _parseSsdpResponse(String response, String ip) {
    final locationMatch = RegExp(r'LOCATION:\s*(.+)', caseSensitive: false).firstMatch(response);
    final serverMatch = RegExp(r'SERVER:\s*(.+)', caseSensitive: false).firstMatch(response);
    final usnMatch = RegExp(r'USN:\s*(.+)', caseSensitive: false).firstMatch(response);

    if (locationMatch == null && serverMatch == null) return null;

    final server = serverMatch?.group(1) ?? '';
    final usn = usnMatch?.group(1) ?? '';

    // Check if this is a Panasonic TV
    final isPanasonic = server.contains('Panasonic') ||
        usn.contains('panasonic') ||
        response.contains('panasonic');

    if (!isPanasonic) return null;

    final name = 'Panasonic TV ($ip)';

    return TvDeviceInfo(
      name: name,
      ipAddress: ip,
      brand: TvBrand.panasonic,
      modelName: _extractModelName(server),
    );
  }

  static String? _extractModelName(String server) {
    final match = RegExp(r'Panasonic[- ](\w+)').firstMatch(server);
    return match?.group(1);
  }
}
