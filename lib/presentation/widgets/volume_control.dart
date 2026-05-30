import 'package:flutter/material.dart';

class VolumeControl extends StatelessWidget {
  final VoidCallback onVolumeUp;
  final VoidCallback onVolumeDown;
  final VoidCallback onChannelUp;
  final VoidCallback onChannelDown;
  final VoidCallback onMute;

  const VolumeControl({
    super.key,
    required this.onVolumeUp,
    required this.onVolumeDown,
    required this.onChannelUp,
    required this.onChannelDown,
    required this.onMute,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            _ControlButton(
              icon: Icons.volume_up,
              onPressed: onVolumeUp,
            ),
            const SizedBox(height: 8),
            const Text('Vol', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            _ControlButton(
              icon: Icons.volume_down,
              onPressed: onVolumeDown,
            ),
          ],
        ),
        _ControlButton(
          icon: Icons.volume_off,
          onPressed: onMute,
        ),
        Column(
          children: [
            _ControlButton(
              icon: Icons.keyboard_arrow_up,
              onPressed: onChannelUp,
            ),
            const SizedBox(height: 8),
            const Text('CH', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            _ControlButton(
              icon: Icons.keyboard_arrow_down,
              onPressed: onChannelDown,
            ),
          ],
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _ControlButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onPressed,
        child: Icon(icon, size: 24),
      ),
    );
  }
}
