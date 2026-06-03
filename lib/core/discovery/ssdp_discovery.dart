import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../../domain/models/tv_device_info.dart';

/// Discovers Panasonic TVs on the local network using SSDP (UPnP).
class SsdpDiscovery {
  static const _multicastAddress = '239.255.255.250';
  static const _port = 1900;
  static const _mx = 3; // seconds to wait for responses
  static const _channel = MethodChannel('com.seion.tvRemote/ssdp_discovery');

  /// Searches for Panasonic Viera TVs via SSDP M-SEARCH.
  ///
  /// Returns a list of discovered [TvDeviceInfo] objects.
  /// On Web, always returns an empty list (SSDP requires raw sockets).
  /// On iOS, uses Network.framework via method channel to avoid the multicast
  /// entitlement requirement. Falls back to subnet scan if SSDP returns empty.
  static Future<List<TvDeviceInfo>> discover({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    // Always run SSDP and subnet scan in parallel so the loading indicator
    // stays visible until all methods have completed.
    final ssdpFuture = Platform.isIOS
        ? _discoverIOS(const Duration(seconds: 5))
        : _discoverNative(timeout);
    final scanFuture = _scanSubnet();
    final results = await Future.wait([ssdpFuture, scanFuture]);
    final ssdpDevices = results[0];
    final scanDevices = results[1];

    // Merge, preferring SSDP results first, deduplicating by IP:Port
    final seen = <String>{};
    final merged = <TvDeviceInfo>[];
    for (final d in [...ssdpDevices, ...scanDevices]) {
      final key = '${d.ipAddress}:${d.port}';
      if (!seen.contains(key)) {
        seen.add(key);
        merged.add(d);
      }
    }
    return merged;
  }

  /// iOS-specific discovery using Network.framework (no multicast entitlement needed).
  static Future<List<TvDeviceInfo>> _discoverIOS(Duration timeout) async {
    try {
      final result = await _channel.invokeMethod('discover', {
        'timeout': timeout.inMilliseconds.toDouble() / 1000.0,
      });
      if (result == null) return [];
      final list = result as List<dynamic>;
      return list
          .map((e) => TvDeviceInfo.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Native Dart implementation for Android, macOS, etc.
  static Future<List<TvDeviceInfo>> _discoverNative(Duration timeout) async {
    final devices = <TvDeviceInfo>{};

    final RawDatagramSocket socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    } catch (_) {
      return [];
    }

    socket.broadcastEnabled = true;
    socket.readEventsEnabled = true;

    for (final st in [
      'urn:panasonic-com:service:p00NetworkControl:1',
      'ssdp:all',
      'upnp:rootdevice',
    ]) {
      final searchMessage = 'M-SEARCH * HTTP/1.1\r\n'
          'HOST: $_multicastAddress:$_port\r\n'
          'MAN: "ssdp:discover"\r\n'
          'MX: $_mx\r\n'
          'ST: $st\r\n'
          '\r\n';

      try {
        socket.send(
          searchMessage.codeUnits,
          InternetAddress(_multicastAddress),
          _port,
        );
      } catch (_) {
        // Silently ignore send errors — multicast may be blocked
      }
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

  /// Fallback: scans the local subnet for Panasonic TVs on port 55000.
  /// Uses TCP connect to detect open ports (no multicast needed).
  static Future<List<TvDeviceInfo>> _scanSubnet() async {
    try {
      final ip = await _getWifiIP();
      if (ip == null) return [];

      final prefix = ip.substring(0, ip.lastIndexOf('.'));
      final devices = <TvDeviceInfo>[];

      // Scan /24 subnet in batches to limit concurrency
      const batchSize = 30;
      for (var i = 1; i <= 254; i += batchSize) {
        final batch = <Future<void>>[];
        for (var j = i; j < i + batchSize && j <= 254; j++) {
          final targetIp = '$prefix.$j';
          batch.add(
            _tryConnect(targetIp, 55000).then((open) {
              if (open) {
                devices.add(TvDeviceInfo(
                  name: 'Panasonic TV ($targetIp)',
                  ipAddress: targetIp,
                  brand: TvBrand.panasonic,
                ));
              }
            }),
          );
        }
        await Future.wait(batch);
      }
      return devices;
    } catch (_) {
      return [];
    }
  }

  /// Returns true if a TCP connection to [ip]:[port] succeeds quickly.
  static Future<bool> _tryConnect(String ip, int port) async {
    try {
      final socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(milliseconds: 300),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Returns the WiFi interface's IPv4 address, or null if not connected.
  static Future<String?> _getWifiIP() async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );
    // Common WiFi interface names across platforms
    const wifiNames = {'en0', 'wlan0'};
    for (final iface in interfaces) {
      if (wifiNames.contains(iface.name)) {
        return iface.addresses.first.address;
      }
    }
    // Fallback: return first non-loopback IPv4 address
    if (interfaces.isNotEmpty) {
      return interfaces.first.addresses.first.address;
    }
    return null;
  }

  static TvDeviceInfo? _parseSsdpResponse(String response, String ip) {
    final serverMatch =
        RegExp(r'SERVER:\s*(.+)', caseSensitive: false).firstMatch(response);
    final usnMatch =
        RegExp(r'USN:\s*(.+)', caseSensitive: false).firstMatch(response);

    if (serverMatch == null && usnMatch == null) return null;

    final server = serverMatch?.group(1) ?? '';
    final usn = usnMatch?.group(1) ?? '';

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
