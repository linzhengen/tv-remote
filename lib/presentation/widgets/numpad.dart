import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/remote_command.dart';
import '../providers/tv_provider.dart';
import 'remote_button.dart';

class NumpadWidget extends ConsumerWidget {
  const NumpadWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sendCommand = ref.watch(sendCommandProvider);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            RemoteButton(
              command: RemoteCommand.num1,
              onPressed: sendCommand,
              compact: true,
            ),
            RemoteButton(
              command: RemoteCommand.num2,
              onPressed: sendCommand,
              compact: true,
            ),
            RemoteButton(
              command: RemoteCommand.num3,
              onPressed: sendCommand,
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
              onPressed: sendCommand,
              compact: true,
            ),
            RemoteButton(
              command: RemoteCommand.num5,
              onPressed: sendCommand,
              compact: true,
            ),
            RemoteButton(
              command: RemoteCommand.num6,
              onPressed: sendCommand,
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
              onPressed: sendCommand,
              compact: true,
            ),
            RemoteButton(
              command: RemoteCommand.num8,
              onPressed: sendCommand,
              compact: true,
            ),
            RemoteButton(
              command: RemoteCommand.num9,
              onPressed: sendCommand,
              compact: true,
            ),
          ],
        ),
        const SizedBox(height: 8),
        RemoteButton(
          command: RemoteCommand.num0,
          onPressed: sendCommand,
          compact: true,
          size: 100,
        ),
      ],
    );
  }
}
