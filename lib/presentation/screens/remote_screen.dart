import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/remote_command.dart';
import '../providers/tv_provider.dart';
import '../widgets/remote_button.dart';
import '../widgets/dpad.dart';
import '../widgets/numpad.dart';
import '../widgets/volume_control.dart';
import '../widgets/input_selector.dart';
import 'settings_screen.dart';

class RemoteScreen extends ConsumerWidget {
  const RemoteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(currentDeviceProvider);
    final isConnected = ref.watch(isConnectedProvider);
    final sendCommand = ref.watch(sendCommandProvider);
    final disconnect = ref.watch(disconnectProvider);

    Future<void> safeSendCommand(RemoteCommand cmd) async {
      final error = await sendCommand(cmd);
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(device?.name ?? 'Remote'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
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
              // Power button
              RemoteButton(
                command: RemoteCommand.power,
                onPressed: safeSendCommand,
                compact: true,
                size: 72,
              ),
              const SizedBox(height: 16),

              // Connection status
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              DpadWidget(onCommand: safeSendCommand),
              const SizedBox(height: 20),

              // Volume & Channel
              VolumeControl(
                onVolumeUp: () => safeSendCommand(RemoteCommand.volumeUp),
                onVolumeDown: () => safeSendCommand(RemoteCommand.volumeDown),
                onChannelUp: () => safeSendCommand(RemoteCommand.channelUp),
                onChannelDown: () =>
                    safeSendCommand(RemoteCommand.channelDown),
                onMute: () => safeSendCommand(RemoteCommand.mute),
              ),
              const SizedBox(height: 20),

              // Input Selector
              InputSelector(onCommand: safeSendCommand),
              const SizedBox(height: 20),

              // Media Controls
              _MediaRow(sendCommand: safeSendCommand),
              const SizedBox(height: 20),

              // Number Pad
              NumpadWidget(onCommand: safeSendCommand),
              const SizedBox(height: 20),

              // Quick Access Row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  RemoteButton(
                    command: RemoteCommand.home,
                    onPressed: safeSendCommand,
                    compact: true,
                  ),
                  RemoteButton(
                    command: RemoteCommand.menu,
                    onPressed: safeSendCommand,
                    compact: true,
                  ),
                  RemoteButton(
                    command: RemoteCommand.apps,
                    onPressed: safeSendCommand,
                    compact: true,
                  ),
                  RemoteButton(
                    command: RemoteCommand.internet,
                    onPressed: safeSendCommand,
                    compact: true,
                  ),
                  RemoteButton(
                    command: RemoteCommand.guide,
                    onPressed: safeSendCommand,
                    compact: true,
                  ),
                  RemoteButton(
                    command: RemoteCommand.info,
                    onPressed: safeSendCommand,
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
                    onPressed: safeSendCommand,
                  ),
                  _ColorButton(
                    color: Colors.green,
                    command: RemoteCommand.green,
                    onPressed: safeSendCommand,
                  ),
                  _ColorButton(
                    color: Colors.blue,
                    command: RemoteCommand.blue,
                    onPressed: safeSendCommand,
                  ),
                  _ColorButton(
                    color: Colors.yellow,
                    command: RemoteCommand.yellow,
                    onPressed: safeSendCommand,
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
            compact: true),
        RemoteButton(
            command: RemoteCommand.play,
            onPressed: sendCommand,
            compact: true),
        RemoteButton(
            command: RemoteCommand.fastForward,
            onPressed: sendCommand,
            compact: true),
        RemoteButton(
            command: RemoteCommand.pause,
            onPressed: sendCommand,
            compact: true),
        RemoteButton(
            command: RemoteCommand.stop,
            onPressed: sendCommand,
            compact: true),
        RemoteButton(
            command: RemoteCommand.skipPrev,
            onPressed: sendCommand,
            compact: true),
        RemoteButton(
            command: RemoteCommand.skipNext,
            onPressed: sendCommand,
            compact: true),
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
