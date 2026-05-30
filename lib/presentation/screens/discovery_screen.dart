import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/tv_device_info.dart';
import '../providers/tv_provider.dart';

class DiscoveryScreen extends ConsumerWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedDevicesProvider);
    final discoveredAsync = ref.watch(discoveryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TV Remote'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Discovered devices
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Nearby TVs',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () =>
                        ref.invalidate(discoveryProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Scan'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: discoveredAsync.when(
                data: (devices) => _DeviceList(
                  devices: devices,
                  isSaved: false,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Discovery error: $err')),
              ),
            ),
            const Divider(),
            // Saved devices
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Saved TVs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: savedAsync.when(
                data: (devices) => _DeviceList(
                  devices: devices,
                  isSaved: true,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) =>
                    const Center(child: Text('No saved devices')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDeviceDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDeviceDialog(BuildContext context, WidgetRef ref) {
    final ipController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add TV manually'),
        content: TextField(
          controller: ipController,
          decoration: const InputDecoration(
            labelText: 'IP Address',
            hintText: '192.168.x.x',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final ip = ipController.text.trim();
              if (ip.isNotEmpty) {
                final device = TvDeviceInfo(
                  name: 'Panasonic TV ($ip)',
                  ipAddress: ip,
                  brand: TvBrand.panasonic,
                );
                ref.read(connectToDeviceProvider(device));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}

class _DeviceList extends ConsumerWidget {
  final List<TvDeviceInfo> devices;
  final bool isSaved;

  const _DeviceList({required this.devices, required this.isSaved});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (devices.isEmpty) {
      return const Center(
        child: Text(
          'No devices found',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: devices.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final device = devices[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              Icons.tv,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(device.name),
            subtitle: Text('${device.ipAddress}:${device.port}'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              ref.read(connectToDeviceProvider(device));
            },
          ),
        );
      },
    );
  }
}
