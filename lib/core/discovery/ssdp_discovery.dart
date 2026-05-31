import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../domain/models/tv_device_info.dart';

/// Discovers Panasonic TVs on the local network using SSDP (UPnP).
class SsdpDiscovery {
  static const _multicastAddress = '239.255.255.250';
  static const _port = 1900;
  static const _mx = 3; // seconds to wait for responses

  /// Searches for Panasonic Viera TVs via SSDP M-SEARCH.
  ///
  /// Returns a list of discovered [TvDeviceInfo] objects.
  /// On Web, always returns an empty list (SSDP requires raw sockets).
  static Future<List<TvDeviceInfo>> discover({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (kIsWeb) return []; // SSDP not supported on web

    final devices = <TvDeviceInfo>{};

    final RawDatagramSocket socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    } catch (_) {
      // IPv6-only or no network — return empty
      return [];
    }

    socket.broadcastEnabled = true;
    socket.readEventsEnabled = true;

    // First try Panasonic-specific ST, then ssdp:all for broader discovery
    for (final st in [
      'urn:panasonic-com:service:p00NetworkControl:1',
      'ssdp:all',
    ]) {
      final searchMessage = 'M-SEARCH * HTTP/1.1\r\n'
          'HOST: $_multicastAddress:$_port\r\n'
          'MAN: "ssdp:discover"\r\n'
          'MX: $_mx\r\n'
          'ST: $st\r\n'
          '\r\n';

      socket.send(
        searchMessage.codeUnits,
        InternetAddress(_multicastAddress),
        _port,
      );
    }

    final completer = Completer<void>();
    Timer(timeout, () {
      if (!completer.isCompleted) completer.complete();
    });

    socket.listen(
      (event) {
        switch (event) {
          case RawSocketEvent.read:
            final datagram = socket.receive();
            if (datagram != null) {
              final data = String.fromCharCodes(datagram.data);
              final device =
                  _parseSsdpResponse(data, datagram.address.address);
              if (device != null) {
                devices.add(device);
              }
            }
          case RawSocketEvent.closed:
            if (!completer.isCompleted) completer.complete();
          case RawSocketEvent.write:
            break;
          case RawSocketEvent.readClosed:
            if (!completer.isCompleted) completer.complete();
        }
      },
      onError: (_) {
        if (!completer.isCompleted) completer.complete();
      },
    );

    await completer.future;
    socket.close();
    return devices.toList();
  }

  static TvDeviceInfo? _parseSsdpResponse(String response, String ip) {
    final serverMatch =
        RegExp(r'SERVER:\s*(.+)', caseSensitive: false).firstMatch(response);
    final usnMatch =
        RegExp(r'USN:\s*(.+)', caseSensitive: false).firstMatch(response);

    if (serverMatch == null && usnMatch == null) return null;

    final server = serverMatch?.group(1) ?? '';
    final usn = usnMatch?.group(1) ?? '';

    // Check if this is a Panasonic TV
    final lower = response.toLowerCase();
    final isPanasonic = server.contains('Panasonic') ||
        usn.contains('panasonic') ||
        lower.contains('panasonic') ||
        lower.contains('viera');

    if (!isPanasonic) return null;

    return TvDeviceInfo(
      name: 'Panasonic TV ($ip)',
      ipAddress: ip,
      brand: TvBrand.panasonic,
      modelName: _extractModelName(server),
    );
  }

  static String? _extractModelName(String server) {
    final match = RegExp(r'Panasonic[- ](\w+)', caseSensitive: false)
        .firstMatch(server);
    return match?.group(1);
  }
}
