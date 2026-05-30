import 'package:flutter/material.dart';
import '../../domain/models/remote_command.dart';

class RemoteButton extends StatelessWidget {
  final RemoteCommand command;
  final Future<void> Function(RemoteCommand) onPressed;
  final bool compact;
  final double? size;

  const RemoteButton({
    super.key,
    required this.command,
    required this.onPressed,
    this.compact = false,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _commandIcon(command);
    final label = command.label;

    if (compact) {
      final s = size ?? 52;
      return SizedBox(
        width: s,
        height: s,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => onPressed(command),
          child: icon != null
              ? Icon(icon, size: 22)
              : Text(
                  label,
                  style: const TextStyle(fontSize: 13),
                ),
        ),
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      onPressed: () => onPressed(command),
      child: icon != null
          ? Icon(icon, size: 28)
          : Text(label),
    );
  }

  static IconData? _commandIcon(RemoteCommand cmd) {
    return switch (cmd) {
      RemoteCommand.power => Icons.power_settings_new,
      RemoteCommand.volumeUp => Icons.volume_up,
      RemoteCommand.volumeDown => Icons.volume_down,
      RemoteCommand.mute => Icons.volume_off,
      RemoteCommand.channelUp => Icons.keyboard_arrow_up,
      RemoteCommand.channelDown => Icons.keyboard_arrow_down,
      RemoteCommand.up => Icons.keyboard_arrow_up,
      RemoteCommand.down => Icons.keyboard_arrow_down,
      RemoteCommand.left => Icons.keyboard_arrow_left,
      RemoteCommand.right => Icons.keyboard_arrow_right,
      RemoteCommand.ok => Icons.check_circle_outline,
      RemoteCommand.back => Icons.arrow_back,
      RemoteCommand.home => Icons.home,
      RemoteCommand.play => Icons.play_arrow,
      RemoteCommand.pause => Icons.pause,
      RemoteCommand.stop => Icons.stop,
      RemoteCommand.rewind => Icons.fast_rewind,
      RemoteCommand.fastForward => Icons.fast_forward,
      RemoteCommand.skipNext => Icons.skip_next,
      RemoteCommand.skipPrev => Icons.skip_previous,
      RemoteCommand.record => Icons.fiber_manual_record,
      RemoteCommand.menu => Icons.menu,
      RemoteCommand.guide => Icons.live_tv,
      RemoteCommand.info => Icons.info_outline,
      RemoteCommand.apps => Icons.apps,
      RemoteCommand.internet => Icons.language,
      _ => null,
    };
  }
}
