import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/remote_command.dart';
import '../providers/tv_provider.dart';
import '../widgets/remote_button.dart';
import '../widgets/control_pad.dart';
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isConnected ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 10),
            Text(device?.name ?? 'Remote'),
          ],
        ),
        centerTitle: false,
        actions: [
          RemoteButton(
            command: RemoteCommand.power,
            onPressed: safeSendCommand,
            compact: true,
            size: 40,
          ),
          IconButton(
            icon: const Icon(Icons.settings, size: 22),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 22),
            onPressed: () => disconnect(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // ── Control Pad (D-Pad + Vol/CH rockers) ──
              ControlPad(onCommand: safeSendCommand),
              const SizedBox(height: 16),
              const Divider(indent: 16, endIndent: 16),

              // ── Number Pad (collapsible) ──
              _CollapsibleNumpad(onCommand: safeSendCommand),
              const Divider(indent: 16, endIndent: 16),

              // ── Input / Quick access row ──
              _SectionLabel('Input'),
              const SizedBox(height: 8),
              _ActionRow(onCommand: safeSendCommand),
              const SizedBox(height: 4),
              _ActionRow2(onCommand: safeSendCommand),
              const Divider(indent: 16, endIndent: 16),

              // ── Media controls ──
              _SectionLabel('Media'),
              const SizedBox(height: 8),
              _MediaRow(sendCommand: safeSendCommand),
              const Divider(indent: 16, endIndent: 16),

              // ── Color buttons ──
              _SectionLabel('Color'),
              const SizedBox(height: 8),
              _ColorRow(onCommand: safeSendCommand),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section label ──────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Divider(color: Colors.grey[800], height: 1),
        ),
      ],
    );
  }
}

// ─── Collapsible number pad ─────────────────────────────────

class _CollapsibleNumpad extends StatefulWidget {
  final Future<void> Function(RemoteCommand) onCommand;
  const _CollapsibleNumpad({required this.onCommand});

  @override
  State<_CollapsibleNumpad> createState() => _CollapsibleNumpadState();
}

class _CollapsibleNumpadState extends State<_CollapsibleNumpad> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Text(
                  _expanded ? 'Hide Numpad' : 'Numpad',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          _NumPad(onCommand: widget.onCommand),
        ],
      ],
    );
  }
}

class _NumPad extends StatelessWidget {
  final Future<void> Function(RemoteCommand) onCommand;
  const _NumPad({required this.onCommand});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _NumRow(commands: const [
          RemoteCommand.num1,
          RemoteCommand.num2,
          RemoteCommand.num3,
        ], onCommand: onCommand),
        const SizedBox(height: 6),
        _NumRow(commands: const [
          RemoteCommand.num4,
          RemoteCommand.num5,
          RemoteCommand.num6,
        ], onCommand: onCommand),
        const SizedBox(height: 6),
        _NumRow(commands: const [
          RemoteCommand.num7,
          RemoteCommand.num8,
          RemoteCommand.num9,
        ], onCommand: onCommand),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 48),
            RemoteButton(
              command: RemoteCommand.num0,
              onPressed: onCommand,
              compact: true,
              size: 56,
            ),
            const SizedBox(width: 48),
          ],
        ),
      ],
    );
  }
}

class _NumRow extends StatelessWidget {
  final List<RemoteCommand> commands;
  final Future<void> Function(RemoteCommand) onCommand;

  const _NumRow({required this.commands, required this.onCommand});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final cmd in commands) ...[
          RemoteButton(command: cmd, onPressed: onCommand, compact: true),
          const SizedBox(width: 6),
        ],
      ],
    );
  }
}

// ─── Action rows ────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final Future<void> Function(RemoteCommand) onCommand;
  const _ActionRow({required this.onCommand});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        RemoteButton(command: RemoteCommand.hdmi1, onPressed: onCommand, compact: true),
        RemoteButton(command: RemoteCommand.tvTuner, onPressed: onCommand, compact: true),
        RemoteButton(command: RemoteCommand.networkInput, onPressed: onCommand, compact: true),
        RemoteButton(command: RemoteCommand.changeInput, onPressed: onCommand, compact: true),
        RemoteButton(command: RemoteCommand.home, onPressed: onCommand, compact: true),
      ],
    );
  }
}

class _ActionRow2 extends StatelessWidget {
  final Future<void> Function(RemoteCommand) onCommand;
  const _ActionRow2({required this.onCommand});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        RemoteButton(command: RemoteCommand.menu, onPressed: onCommand, compact: true),
        RemoteButton(command: RemoteCommand.apps, onPressed: onCommand, compact: true),
        RemoteButton(command: RemoteCommand.internet, onPressed: onCommand, compact: true),
        RemoteButton(command: RemoteCommand.guide, onPressed: onCommand, compact: true),
        RemoteButton(command: RemoteCommand.info, onPressed: onCommand, compact: true),
      ],
    );
  }
}

// ─── Media row ──────────────────────────────────────────────

class _MediaRow extends StatelessWidget {
  final Future<void> Function(RemoteCommand) sendCommand;
  const _MediaRow({required this.sendCommand});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        RemoteButton(command: RemoteCommand.skipPrev, onPressed: sendCommand, compact: true),
        RemoteButton(command: RemoteCommand.rewind, onPressed: sendCommand, compact: true),
        _MediaButton(icon: Icons.play_arrow, onPressed: () => sendCommand(RemoteCommand.play)),
        _MediaButton(icon: Icons.pause, onPressed: () => sendCommand(RemoteCommand.pause)),
        RemoteButton(command: RemoteCommand.stop, onPressed: sendCommand, compact: true),
        RemoteButton(command: RemoteCommand.fastForward, onPressed: sendCommand, compact: true),
        RemoteButton(command: RemoteCommand.skipNext, onPressed: sendCommand, compact: true),
      ],
    );
  }
}

class _MediaButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _MediaButton({required this.icon, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primary,
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onPrimary,
          size: 24,
        ),
      ),
    );
  }
}

// ─── Color row ──────────────────────────────────────────────

class _ColorRow extends StatelessWidget {
  final Future<void> Function(RemoteCommand) onCommand;
  const _ColorRow({required this.onCommand});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ColorDot(color: Colors.red, onTap: () => onCommand(RemoteCommand.red)),
        const SizedBox(width: 16),
        _ColorDot(color: Colors.green, onTap: () => onCommand(RemoteCommand.green)),
        const SizedBox(width: 16),
        _ColorDot(color: Colors.blue, onTap: () => onCommand(RemoteCommand.blue)),
        const SizedBox(width: 16),
        _ColorDot(color: Colors.yellow, onTap: () => onCommand(RemoteCommand.yellow)),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _ColorDot({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}
