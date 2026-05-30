import 'remote_command.dart';

typedef CommandCallback = void Function(RemoteCommand command);

class RemoteButtonLayout {
  final List<ButtonGroup> groups;

  const RemoteButtonLayout({required this.groups});
}

class ButtonGroup {
  final String label;
  final List<ButtonRow> rows;

  const ButtonGroup({this.label = '', required this.rows});
}

class ButtonRow {
  final List<RemoteCommand> commands;

  const ButtonRow(this.commands);
}

/// Default remote layout matching a typical TV remote.
const defaultRemoteLayout = RemoteButtonLayout(groups: [
  ButtonGroup(label: 'Power & Input', rows: [
    ButtonRow([RemoteCommand.power, RemoteCommand.changeInput]),
  ]),
  ButtonGroup(label: 'Navigation', rows: [
    ButtonRow([RemoteCommand.home, RemoteCommand.up, RemoteCommand.menu]),
    ButtonRow([RemoteCommand.left, RemoteCommand.ok, RemoteCommand.right]),
    ButtonRow([RemoteCommand.back, RemoteCommand.down, RemoteCommand.info]),
  ]),
  ButtonGroup(label: 'Volume & Channel', rows: [
    ButtonRow([
      RemoteCommand.volumeUp,
      RemoteCommand.channelUp,
      RemoteCommand.mute,
    ]),
    ButtonRow([
      RemoteCommand.volumeDown,
      RemoteCommand.channelDown,
      RemoteCommand.lastView,
    ]),
  ]),
  ButtonGroup(label: 'Media', rows: [
    ButtonRow([
      RemoteCommand.rewind,
      RemoteCommand.play,
      RemoteCommand.fastForward,
    ]),
    ButtonRow([
      RemoteCommand.skipPrev,
      RemoteCommand.pause,
      RemoteCommand.skipNext,
    ]),
    ButtonRow([RemoteCommand.stop, RemoteCommand.record]),
  ]),
  ButtonGroup(label: 'Numbers', rows: [
    ButtonRow([
      RemoteCommand.num1,
      RemoteCommand.num2,
      RemoteCommand.num3,
    ]),
    ButtonRow([
      RemoteCommand.num4,
      RemoteCommand.num5,
      RemoteCommand.num6,
    ]),
    ButtonRow([
      RemoteCommand.num7,
      RemoteCommand.num8,
      RemoteCommand.num9,
    ]),
    ButtonRow([RemoteCommand.num0]),
  ]),
  ButtonGroup(label: 'Color', rows: [
    ButtonRow([
      RemoteCommand.red,
      RemoteCommand.green,
      RemoteCommand.blue,
      RemoteCommand.yellow,
    ]),
  ]),
]);
