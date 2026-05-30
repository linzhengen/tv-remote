import '../models/tv_device_info.dart';
import '../models/remote_command.dart';

/// Common interface for all TV manufacturers.
///
/// To add a new manufacturer, implement this interface and register it in
/// [data/manufacturers/] — no changes needed to domain or presentation layers.
abstract class TvController {
  Future<bool> connect(TvDeviceInfo device);
  Future<void> disconnect();
  Future<void> sendCommand(RemoteCommand command);
  Future<void> powerOn(TvDeviceInfo device);
  bool get isConnected;
}
