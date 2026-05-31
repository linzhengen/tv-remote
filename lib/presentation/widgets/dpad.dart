import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/remote_command.dart';

class DpadWidget extends StatelessWidget {
  final Future<void> Function(RemoteCommand) onCommand;
  const DpadWidget({super.key, required this.onCommand});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ArrowButton(
          icon: Icons.keyboard_arrow_up,
          onPressed: () => onCommand(RemoteCommand.up),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ArrowButton(
              icon: Icons.keyboard_arrow_left,
              onPressed: () => onCommand(RemoteCommand.left),
            ),
            const SizedBox(width: 12),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              ),
              child: IconButton(
                icon: const Text(
                  'OK',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: () => onCommand(RemoteCommand.ok),
              ),
            ),
            const SizedBox(width: 12),
            _ArrowButton(
              icon: Icons.keyboard_arrow_right,
              onPressed: () => onCommand(RemoteCommand.right),
            ),
          ],
        ),
        _ArrowButton(
          icon: Icons.keyboard_arrow_down,
          onPressed: () => onCommand(RemoteCommand.down),
        ),
      ],
    );
  }
}

class _ArrowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _ArrowButton({required this.icon, required this.onPressed});

  @override
  State<_ArrowButton> createState() => _ArrowButtonState();
}

class _ArrowButtonState extends State<_ArrowButton> {
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
      width: 56,
      height: 56,
      child: GestureDetector(
        onLongPressStart: (_) => _startRepeat(),
        onLongPressEnd: (_) => _stopRepeat(),
        onLongPressCancel: _stopRepeat,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            widget.onPressed();
          },
          child: Icon(widget.icon, size: 28),
        ),
      ),
    );
  }
}
