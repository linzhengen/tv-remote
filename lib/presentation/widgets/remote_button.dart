import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/remote_command.dart';
import '../../data/manufacturers/panasonic/panasonic_commands.dart';

class RemoteButton extends StatefulWidget {
  final RemoteCommand command;
  final Future<void> Function(RemoteCommand) onPressed;
  final bool compact;
  final double? size;
  final bool enableRepeat;

  const RemoteButton({
    super.key,
    required this.command,
    required this.onPressed,
    this.compact = false,
    this.size,
    this.enableRepeat = false,
  });

  @override
  State<RemoteButton> createState() => _RemoteButtonState();
}

class _RemoteButtonState extends State<RemoteButton> {
  Timer? _repeatTimer;

  @override
  void dispose() {
    _repeatTimer?.cancel();
    super.dispose();
  }

  void _startRepeat() {
    HapticFeedback.lightImpact();
    widget.onPressed(widget.command);

    if (widget.enableRepeat) {
      _repeatTimer = Timer.periodic(
        PanasonicCommands.repeatDelay,
        (_) => widget.onPressed(widget.command),
      );
    }
  }

  void _stopRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final icon = _commandIcon(widget.command);
    final label = widget.command.label;

    if (widget.compact) {
      final s = widget.size ?? 52;
      return SizedBox(
        width: s,
        height: s,
        child: GestureDetector(
          onLongPressStart: (_) => _startRepeat(),
          onLongPressEnd: (_) => _stopRepeat(),
          onLongPressCancel: _stopRepeat,
          child: Tooltip(
            message: label,
            child: Semantics(
              label: label,
              button: true,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onPressed(widget.command);
                },
                child: icon != null
                    ? Icon(icon, size: 22)
                    : Text(
                        label,
                        style: const TextStyle(fontSize: 13),
                      ),
              ),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onLongPressStart: (_) => _startRepeat(),
      onLongPressEnd: (_) => _stopRepeat(),
      onLongPressCancel: _stopRepeat,
      child: Tooltip(
        message: label,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            widget.onPressed(widget.command);
          },
          child: Semantics(
            label: label,
            button: true,
            child: icon != null ? Icon(icon, size: 28) : Text(label),
          ),
        ),
      ),
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
      RemoteCommand.changeInput => Icons.input,
      RemoteCommand.hdmi1 => Icons.cable,
      RemoteCommand.hdmi2 => Icons.cable,
      RemoteCommand.hdmi3 => Icons.cable,
      RemoteCommand.hdmi4 => Icons.cable,
      RemoteCommand.tvTuner => Icons.live_tv,
      RemoteCommand.networkInput => Icons.wifi,
      _ => null,
    };
  }
}
