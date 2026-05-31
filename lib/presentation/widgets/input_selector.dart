import 'package:flutter/material.dart';

import '../../domain/models/remote_command.dart';

class InputSelector extends StatelessWidget {
  final Future<void> Function(RemoteCommand) onCommand;

  const InputSelector({super.key, required this.onCommand});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.input, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              'Input',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _InputCard(
              label: 'HDMI',
              icon: Icons.cable,
              onTap: () => onCommand(RemoteCommand.hdmi1),
            ),
            _InputCard(
              label: 'TV',
              icon: Icons.live_tv,
              onTap: () => onCommand(RemoteCommand.tvTuner),
            ),
            _InputCard(
              label: 'Apps',
              icon: Icons.wifi,
              onTap: () => onCommand(RemoteCommand.networkInput),
            ),
            _InputCard(
              label: 'Menu',
              icon: Icons.input,
              onTap: () => onCommand(RemoteCommand.changeInput),
            ),
          ],
        ),
      ],
    );
  }
}

class _InputCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _InputCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
