import 'package:tv_remote/domain/interfaces/tv_controller.dart';
import 'package:tv_remote/domain/models/remote_command.dart';
import 'package:tv_remote/domain/models/tv_device_info.dart';

/// Mock TV controller for E2E tests.
///
/// Records all commands sent so tests can inspect history.
/// Set [connectResult] and [commandDelay] before use.
class MockTvController implements TvController {
  /// Whether [connect] should succeed.
  bool connectResult = true;

  /// Simulated network delay for connect/command calls.
  Duration commandDelay = const Duration(milliseconds: 50);

  /// If set, [sendCommand] throws this after [failAfterCommands] calls.
  Object? commandError;

  /// Number of successful commands before [commandError] is thrown.
  int failAfterCommands = 0;

  /// Commands sent, in order (for test assertions).
  final List<RemoteCommand> sentCommands = [];

  /// Device passed to [connect].
  TvDeviceInfo? lastConnectedDevice;

  bool _connected = false;

  @override
  bool get isConnected => _connected;

  @override
  Future<bool> connect(TvDeviceInfo device) async {
    lastConnectedDevice = device;
    if (commandDelay > Duration.zero) {
      await Future<void>.delayed(commandDelay);
    }
    _connected = connectResult;
    return connectResult;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
  }

  @override
  Future<void> powerOn(TvDeviceInfo device) async {
    await connect(device);
    await sendCommand(RemoteCommand.power);
    await disconnect();
  }

  @override
  Future<void> sendCommand(RemoteCommand command) async {
    if (!_connected) {
      throw StateError('Not connected to a TV');
    }
    if (commandError != null && sentCommands.length >= failAfterCommands) {
      throw commandError!;
    }
    if (commandDelay > Duration.zero) {
      await Future<void>.delayed(commandDelay);
    }
    sentCommands.add(command);
  }
}
