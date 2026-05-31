import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/tv_device_info.dart';
import '../providers/tv_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final macAsync = ref.watch(wolMacAddressProvider);
    final savedAsync = ref.watch(savedDevicesProvider);
    final disconnect = ref.watch(disconnectProvider);
    final saveMac = ref.watch(saveMacAddressProvider);
    final deleteDevice = ref.watch(deleteDeviceProvider);

    final macController = TextEditingController();
    macAsync.whenData((mac) => macController.text = mac ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // WOL MAC Address
            const Text(
              'Wake-on-LAN',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Enter your TV\'s MAC address to enable Wake-on-LAN.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: macController,
                    decoration: const InputDecoration(
                      labelText: 'MAC Address',
                      hintText: 'AA:BB:CC:DD:EE:FF',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () =>
                      saveMac(macController.text.trim().toUpperCase()),
                  child: const Text('Save'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Manual IP add
            const Text(
              'Add Device',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _AddDeviceForm(saveMac: saveMac),
            const SizedBox(height: 24),

            // Saved devices
            const Text(
              'Saved Devices',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            savedAsync.when(
              data: (devices) {
                if (devices.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No saved devices',
                        style: TextStyle(color: Colors.grey)),
                  );
                }
                return Column(
                  children: devices
                      .map((d) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.tv),
                              title: Text(d.name),
                              subtitle: Text('${d.ipAddress}:${d.port}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => deleteDevice(d),
                              ),
                            ),
                          ))
                      .toList(),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, _) =>
                  const Text('Error loading devices', style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 24),

            // Disconnect
            OutlinedButton.icon(
              onPressed: () {
                disconnect();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Disconnected')),
                );
              },
              icon: const Icon(Icons.link_off),
              label: const Text('Disconnect'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddDeviceForm extends ConsumerStatefulWidget {
  final Future<void> Function(String) saveMac;
  const _AddDeviceForm({required this.saveMac});

  @override
  ConsumerState<_AddDeviceForm> createState() => _AddDeviceFormState();
}

class _AddDeviceFormState extends ConsumerState<_AddDeviceForm> {
  final _ipController = TextEditingController();

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ipController,
            decoration: const InputDecoration(
              labelText: 'IP Address',
              hintText: '192.168.x.x',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: () {
            final ip = _ipController.text.trim();
            if (ip.isEmpty) return;
            final device = TvDeviceInfo(
              name: 'Panasonic TV ($ip)',
              ipAddress: ip,
              brand: TvBrand.panasonic,
            );
            ref.read(connectToDeviceProvider)(device);
          },
          child: const Text('Connect'),
        ),
      ],
    );
  }
}
