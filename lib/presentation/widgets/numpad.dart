import 'package:flutter/material.dart';

import '../../domain/models/remote_command.dart';
import 'remote_button.dart';

class NumpadWidget extends StatelessWidget {
  final Future<void> Function(RemoteCommand) onCommand;
  const NumpadWidget({super.key, required this.onCommand});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            RemoteButton(
              command: RemoteCommand.num1,
              onPressed: onCommand,
              compact: true,
            ),
            RemoteButton(
              command: RemoteCommand.num2,
              onPressed: onCommand,
              compact: true,
            ),
            RemoteButton(
              command: RemoteCommand.num3,
              onPressed: onCommand,
              compact: true,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            RemoteButton(
              command: RemoteCommand.num4,
              onPressed: onCommand,
              compact: true,
            ),
            RemoteButton(
              command: RemoteCommand.num5,
              onPressed: onCommand,
              compact: true,
            ),
            RemoteButton(
              command: RemoteCommand.num6,
              onPressed: onCommand,
              compact: true,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            RemoteButton(
              command: RemoteCommand.num7,
              onPressed: onCommand,
              compact: true,
            ),
            RemoteButton(
              command: RemoteCommand.num8,
              onPressed: onCommand,
              compact: true,
            ),
            RemoteButton(
              command: RemoteCommand.num9,
              onPressed: onCommand,
              compact: true,
            ),
          ],
        ),
        const SizedBox(height: 8),
        RemoteButton(
          command: RemoteCommand.num0,
          onPressed: onCommand,
          compact: true,
          size: 100,
        ),
      ],
    );
  }
}
