import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/remote_command.dart';
import '../providers/tv_provider.dart';

class DpadWidget extends ConsumerWidget {
  const DpadWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sendCommand = ref.watch(sendCommandProvider);

    return Column(
      children: [
        _ArrowButton(
          icon: Icons.keyboard_arrow_up,
          onPressed: () => sendCommand(RemoteCommand.up),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ArrowButton(
              icon: Icons.keyboard_arrow_left,
              onPressed: () => sendCommand(RemoteCommand.left),
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
                onPressed: () => sendCommand(RemoteCommand.ok),
              ),
            ),
            const SizedBox(width: 12),
            _ArrowButton(
              icon: Icons.keyboard_arrow_right,
              onPressed: () => sendCommand(RemoteCommand.right),
            ),
          ],
        ),
        _ArrowButton(
          icon: Icons.keyboard_arrow_down,
          onPressed: () => sendCommand(RemoteCommand.down),
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _ArrowButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: onPressed,
        child: Icon(icon, size: 28),
      ),
    );
  }
}
