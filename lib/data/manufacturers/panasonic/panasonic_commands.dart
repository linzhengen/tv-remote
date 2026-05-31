import '../../../domain/models/remote_command.dart';

/// Maps [RemoteCommand] to Panasonic NRC key codes.
class PanasonicCommands {
  static const _keyDelay = Duration(milliseconds: 50);

  /// Returns the NRC key event string for a given command.
  static String nrcKey(RemoteCommand command) {
    const map = <RemoteCommand, String>{
      RemoteCommand.power: 'NRC_POWER-ONOFF',
      RemoteCommand.volumeUp: 'NRC_VOLUP-ONOFF',
      RemoteCommand.volumeDown: 'NRC_VOLDOWN-ONOFF',
      RemoteCommand.mute: 'NRC_MUTE-ONOFF',
      RemoteCommand.channelUp: 'NRC_CH_UP-ONOFF',
      RemoteCommand.channelDown: 'NRC_CH_DOWN-ONOFF',
      RemoteCommand.up: 'NRC_UP-ONOFF',
      RemoteCommand.down: 'NRC_DOWN-ONOFF',
      RemoteCommand.left: 'NRC_LEFT-ONOFF',
      RemoteCommand.right: 'NRC_RIGHT-ONOFF',
      RemoteCommand.ok: 'NRC_ENTER-ONOFF',
      RemoteCommand.back: 'NRC_RETURN-ONOFF',
      RemoteCommand.home: 'NRC_HOME-ONOFF',
      RemoteCommand.play: 'NRC_PLAY-ONOFF',
      RemoteCommand.pause: 'NRC_PAUSE-ONOFF',
      RemoteCommand.stop: 'NRC_STOP-ONOFF',
      RemoteCommand.rewind: 'NRC_REW-ONOFF',
      RemoteCommand.fastForward: 'NRC_FF-ONOFF',
      RemoteCommand.skipNext: 'NRC_SKIP_NEXT-ONOFF',
      RemoteCommand.skipPrev: 'NRC_SKIP_PREV-ONOFF',
      RemoteCommand.record: 'NRC_REC-ONOFF',
      RemoteCommand.num0: 'NRC_D0-ONOFF',
      RemoteCommand.num1: 'NRC_D1-ONOFF',
      RemoteCommand.num2: 'NRC_D2-ONOFF',
      RemoteCommand.num3: 'NRC_D3-ONOFF',
      RemoteCommand.num4: 'NRC_D4-ONOFF',
      RemoteCommand.num5: 'NRC_D5-ONOFF',
      RemoteCommand.num6: 'NRC_D6-ONOFF',
      RemoteCommand.num7: 'NRC_D7-ONOFF',
      RemoteCommand.num8: 'NRC_D8-ONOFF',
      RemoteCommand.num9: 'NRC_D9-ONOFF',
      RemoteCommand.changeInput: 'NRC_CHG_INPUT-ONOFF',
      RemoteCommand.hdmi1: 'NRC_HDMI-ONOFF',
      RemoteCommand.hdmi2: 'NRC_HDMI-ONOFF',
      RemoteCommand.hdmi3: 'NRC_HDMI-ONOFF',
      RemoteCommand.hdmi4: 'NRC_HDMI-ONOFF',
      RemoteCommand.tvTuner: 'NRC_TV-ONOFF',
      RemoteCommand.networkInput: 'NRC_CHG_NETWORK-ONOFF',
      RemoteCommand.menu: 'NRC_MENU-ONOFF',
      RemoteCommand.guide: 'NRC_GUIDE-ONOFF',
      RemoteCommand.info: 'NRC_INFO-ONOFF',
      RemoteCommand.red: 'NRC_RED-ONOFF',
      RemoteCommand.green: 'NRC_GREEN-ONOFF',
      RemoteCommand.blue: 'NRC_BLUE-ONOFF',
      RemoteCommand.yellow: 'NRC_YELLOW-ONOFF',
      RemoteCommand.subtitles: 'NRC_STTL-ONOFF',
      RemoteCommand.aspect: 'NRC_ASPECT-ONOFF',
      RemoteCommand.internet: 'NRC_INTERNET-ONOFF',
      RemoteCommand.apps: 'NRC_APPS-ONOFF',
      RemoteCommand.vieraLink: 'NRC_VIERA_LINK-ONOFF',
      RemoteCommand.lastView: 'NRC_R_TUNE-ONOFF',
    };
    return map[command]!;
  }

  /// Duration to wait between rapid successive commands.
  static Duration get repeatDelay => _keyDelay;
}
