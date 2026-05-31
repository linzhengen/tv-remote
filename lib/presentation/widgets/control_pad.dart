import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/remote_command.dart';

/// Combined D-Pad + Volume/Channel rockers in a physical remote layout.
class ControlPad extends StatelessWidget {
  final Future<void> Function(RemoteCommand) onCommand;

  const ControlPad({super.key, required this.onCommand});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Volume rocker (left) | D-Pad (center) | Channel rocker (right)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Volume rocker
            _RockerColumn(
              onUp: () => onCommand(RemoteCommand.volumeUp),
              onDown: () => onCommand(RemoteCommand.volumeDown),
              label: 'Vol',
              color: Colors.blueGrey,
            ),
            const SizedBox(width: 24),
            // D-Pad
            _DpadButtons(
              onUp: () => onCommand(RemoteCommand.up),
              onDown: () => onCommand(RemoteCommand.down),
              onLeft: () => onCommand(RemoteCommand.left),
              onRight: () => onCommand(RemoteCommand.right),
              onOk: () => onCommand(RemoteCommand.ok),
            ),
            const SizedBox(width: 24),
            // Channel rocker
            _RockerColumn(
              onUp: () => onCommand(RemoteCommand.channelUp),
              onDown: () => onCommand(RemoteCommand.channelDown),
              label: 'CH',
              color: Colors.blueGrey,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Mute button
        _SmallButton(
          icon: Icons.volume_off,
          label: 'Mute',
          onPressed: () => onCommand(RemoteCommand.mute),
        ),
      ],
    );
  }
}

class _DpadButtons extends StatelessWidget {
  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onLeft;
  final VoidCallback onRight;
  final VoidCallback onOk;

  const _DpadButtons({
    required this.onUp,
    required this.onDown,
    required this.onLeft,
    required this.onRight,
    required this.onOk,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RepeatButton(
          icon: Icons.keyboard_arrow_up,
          onPressed: onUp,
          size: 48,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RepeatButton(
              icon: Icons.keyboard_arrow_left,
              onPressed: onLeft,
              size: 48,
            ),
            Container(
              width: 64,
              height: 64,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary,
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onOk();
                  },
                  child: const Center(
                    child: Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _RepeatButton(
              icon: Icons.keyboard_arrow_right,
              onPressed: onRight,
              size: 48,
            ),
          ],
        ),
        _RepeatButton(
          icon: Icons.keyboard_arrow_down,
          onPressed: onDown,
          size: 48,
        ),
      ],
    );
  }
}

/// Vertical pair of up/down buttons with a center label.
class _RockerColumn extends StatelessWidget {
  final VoidCallback onUp;
  final VoidCallback onDown;
  final String label;
  final Color color;

  const _RockerColumn({
    required this.onUp,
    required this.onDown,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RepeatButton(
          icon: Icons.keyboard_arrow_up,
          onPressed: onUp,
          size: 52,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
              letterSpacing: 1,
            ),
          ),
        ),
        _RepeatButton(
          icon: Icons.keyboard_arrow_down,
          onPressed: onDown,
          size: 52,
        ),
      ],
    );
  }
}

/// A small secondary button (mute, etc.).
class _SmallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _SmallButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A button that supports long-press repeat.
class _RepeatButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;

  const _RepeatButton({
    required this.icon,
    required this.onPressed,
    this.size = 48,
  });

  @override
  State<_RepeatButton> createState() => _RepeatButtonState();
}

class _RepeatButtonState extends State<_RepeatButton> {
  Timer? _repeatTimer;

  @override
  void dispose() {
    _repeatTimer?.cancel();
    super.dispose();
  }

  void _startRepeat() {
    HapticFeedback.lightImpact();
    widget.onPressed();
    _repeatTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => widget.onPressed(),
    );
  }

  void _stopRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: GestureDetector(
        onLongPressStart: (_) => _startRepeat(),
        onLongPressEnd: (_) => _stopRepeat(),
        onLongPressCancel: _stopRepeat,
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.12),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onPressed();
            },
            child: Icon(
              widget.icon,
              size: 28,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }
}
