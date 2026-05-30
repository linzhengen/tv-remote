import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/remote_command.dart';
import '../providers/tv_provider.dart';
import '../widgets/remote_button.dart';
import '../widgets/dpad.dart';
import '../widgets/numpad.dart';
import '../widgets/volume_control.dart';
import 'discovery_screen.dart';

class RemoteScreen extends ConsumerWidget {
  const RemoteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(currentDeviceProvider);
    final isConnected = ref.watch(isConnectedProvider);
    final sendCommand = ref.watch(sendCommandProvider);
    final disconnect = ref.watch(disconnectProvider);

    if (device == null) {
      return const DiscoveryScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Open settings
            },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => disconnect(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Connection status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isConnected
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isConnected ? Icons.check_circle : Icons.error,
                      color: isConnected ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isConnected ? 'Connected' : 'Disconnected',
                      style: TextStyle(
                        color: isConnected ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // D-Pad (Navigation)
              const DpadWidget(),
              const SizedBox(height: 20),

              // Volume & Channel
              VolumeControl(
                onVolumeUp: () => sendCommand(RemoteCommand.volumeUp),
                onVolumeDown: () => sendCommand(RemoteCommand.volumeDown),
                onChannelUp: () => sendCommand(RemoteCommand.channelUp),
                onChannelDown: () => sendCommand(RemoteCommand.channelDown),
                onMute: () => sendCommand(RemoteCommand.mute),
              ),
              const SizedBox(height: 20),

              // Media Controls
              _MediaRow(sendCommand: sendCommand),
              const SizedBox(height: 20),

              // Number Pad
              const NumpadWidget(),
              const SizedBox(height: 20),

              // Quick Access Row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  RemoteButton(
                    command: RemoteCommand.home,
                    onPressed: sendCommand,
                    compact: true,
                  ),
                  RemoteButton(
                    command: RemoteCommand.menu,
                    onPressed: sendCommand,
                    compact: true,
                  ),
                  RemoteButton(
                    command: RemoteCommand.apps,
                    onPressed: sendCommand,
                    compact: true,
                  ),
                  RemoteButton(
                    command: RemoteCommand.internet,
                    onPressed: sendCommand,
                    compact: true,
                  ),
                  RemoteButton(
                    command: RemoteCommand.guide,
                    onPressed: sendCommand,
                    compact: true,
                  ),
                  RemoteButton(
                    command: RemoteCommand.info,
                    onPressed: sendCommand,
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Color Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ColorButton(
                    color: Colors.red,
                    command: RemoteCommand.red,
                    onPressed: sendCommand,
                  ),
                  _ColorButton(
                    color: Colors.green,
                    command: RemoteCommand.green,
                    onPressed: sendCommand,
                  ),
                  _ColorButton(
                    color: Colors.blue,
                    command: RemoteCommand.blue,
                    onPressed: sendCommand,
                  ),
                  _ColorButton(
                    color: Colors.yellow,
                    command: RemoteCommand.yellow,
                    onPressed: sendCommand,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaRow extends StatelessWidget {
  final Future<void> Function(RemoteCommand) sendCommand;
  const _MediaRow({required this.sendCommand});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        RemoteButton(
          command: RemoteCommand.rewind,
          onPressed: sendCommand,
          compact: true,
        ),
        RemoteButton(
          command: RemoteCommand.play,
          onPressed: sendCommand,
          compact: true,
        ),
        RemoteButton(
          command: RemoteCommand.fastForward,
          onPressed: sendCommand,
          compact: true,
        ),
        RemoteButton(
          command: RemoteCommand.pause,
          onPressed: sendCommand,
          compact: true,
        ),
        RemoteButton(
          command: RemoteCommand.stop,
          onPressed: sendCommand,
          compact: true,
        ),
        RemoteButton(
          command: RemoteCommand.skipPrev,
          onPressed: sendCommand,
          compact: true,
        ),
        RemoteButton(
          command: RemoteCommand.skipNext,
          onPressed: sendCommand,
          compact: true,
        ),
      ],
    );
  }
}

class _ColorButton extends StatelessWidget {
  final Color color;
  final RemoteCommand command;
  final Future<void> Function(RemoteCommand) onPressed;
  const _ColorButton({
    required this.color,
    required this.command,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onPressed(command),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
