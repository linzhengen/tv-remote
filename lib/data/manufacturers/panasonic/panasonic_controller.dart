import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../domain/models/tv_device_info.dart';
import '../../../domain/models/remote_command.dart';
import '../../../domain/interfaces/tv_controller.dart';
import 'panasonic_commands.dart';

/// Panasonic TV controller using Viera NRC SOAP/XML protocol.
///
/// Sends commands to port 55000 via HTTP POST with SOAP envelopes.
/// Uses [dart:io HttpClient] on native platforms and [package:http] on Web.
class PanasonicController implements TvController {
  final HttpClient _httpClient = HttpClient();
  final http.Client _webClient = http.Client();
  String? _ipAddress;
  int _port = 55000;
  bool _connected = false;

  @override
  bool get isConnected => _connected;

  @override
  Future<bool> connect(TvDeviceInfo device) async {
    _ipAddress = device.ipAddress;
    _port = device.port;
    _httpClient.connectionTimeout = const Duration(seconds: 5);

    final connected = await _testConnection();
    _connected = connected;
    return connected;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    _ipAddress = null;
    _httpClient.close();
    _webClient.close();
  }

  @override
  Future<void> sendCommand(RemoteCommand command) async {
    if (!_connected || _ipAddress == null) {
      throw StateError('Not connected to a TV');
    }

    final nrcKey = PanasonicCommands.nrcKey(command);
    final soapBody = _buildSoapEnvelope(nrcKey);
    final url = 'http://$_ipAddress:$_port/nrc/control_0';

    if (kIsWeb) {
      await _webClient.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'text/xml; charset="utf-8"',
          'SOAPACTION':
              '"urn:panasonic-com:service:p00NetworkControl:1#X_SendKey"',
          'Accept': 'text/xml',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
        body: soapBody,
      );
    } else {
      final request = await _httpClient.postUrl(Uri.parse(url));
      request.headers.set('Content-Type', 'text/xml; charset="utf-8"');
      request.headers.set('SOAPACTION',
          '"urn:panasonic-com:service:p00NetworkControl:1#X_SendKey"');
      request.headers.set('Accept', 'text/xml');
      request.headers.set('Cache-Control', 'no-cache');
      request.headers.set('Pragma', 'no-cache');
      request.write(soapBody);

      final response = await request.close();
      await response.drain();
    }
  }

  @override
  Future<void> powerOn(TvDeviceInfo device) async {
    try {
      await connect(device);
      await sendCommand(RemoteCommand.power);
      await disconnect();
    } catch (_) {
      // WOL-only fallback handled externally
    }
  }

  Future<bool> _testConnection() async {
    try {
      if (kIsWeb) {
        // Web: try a simple ping via HTTP to the NRC endpoint
        await _webClient
            .post(
              Uri.parse('http://$_ipAddress:$_port/nrc/control_0'),
              headers: {'Content-Type': 'text/xml; charset="utf-8"'},
              body: _buildSoapEnvelope('NRC_POWER-ONOFF'),
            )
            .timeout(const Duration(seconds: 3));
      } else {
        final socket = await Socket.connect(
          _ipAddress!,
          _port,
          timeout: const Duration(seconds: 3),
        );
        socket.destroy();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  String _buildSoapEnvelope(String nrcKey) {
    return '''<?xml version="1.0" encoding="utf-8"?>
<s:Envelope
    s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"
    xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
    <s:Body>
        <u:X_SendKey xmlns:u="urn:panasonic-com:service:p00NetworkControl:1">
            <X_KeyEvent>$nrcKey</X_KeyEvent>
        </u:X_SendKey>
    </s:Body>
</s:Envelope>''';
  }
}
