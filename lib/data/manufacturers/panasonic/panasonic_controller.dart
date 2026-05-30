import 'dart:io';

import '../../../domain/models/tv_device_info.dart';
import '../../../domain/models/remote_command.dart';
import '../../../domain/interfaces/tv_controller.dart';
import 'panasonic_commands.dart';

/// Panasonic TV controller using Viera NRC SOAP/XML protocol.
///
/// Sends commands to port 55000 via HTTP POST with SOAP envelopes.
/// For TVs requiring PIN authentication (My Home Screen 6+), the encrypted
/// handshake is not yet implemented — see [PanasonicEncryption] stub.
class PanasonicController implements TvController {
  final HttpClient _httpClient = HttpClient();
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
  }

  @override
  Future<void> sendCommand(RemoteCommand command) async {
    if (!_connected || _ipAddress == null) {
      throw StateError('Not connected to a TV');
    }

    final nrcKey = PanasonicCommands.nrcKey(command);
    final soapBody = _buildSoapEnvelope(nrcKey);

    final request = await _httpClient.postUrl(
      Uri.parse('http://$_ipAddress:$_port/nrc/control_0'),
    );
    request.headers.set('Content-Type', 'text/xml; charset="utf-8"');
    request.headers.set('SOAPACTION', '"urn:panasonic-com:service:p00NetworkControl:1#X_SendKey"');
    request.headers.set('Accept', 'text/xml');
    request.headers.set('Cache-Control', 'no-cache');
    request.headers.set('Pragma', 'no-cache');
    request.write(soapBody);

    final response = await request.close();
    await response.drain();
  }

  @override
  Future<void> powerOn(TvDeviceInfo device) async {
    // Panasonic TVs typically respond to Wake-on-LAN for power-on.
    // This is handled by the WakeOnLan utility in core/discovery/.
    // For Panasonic specifically, we also try a power command via NRC
    // in case the TV is in standby with network active.
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
      final request = await _httpClient
          .getUrl(Uri.parse('http://$_ipAddress:$_port/'))
          .timeout(const Duration(seconds: 3));
      await request.close();
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
