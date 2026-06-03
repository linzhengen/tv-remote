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
    final connectingDevice = ref.watch(connectingDeviceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TV Remote'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SafeArea(
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
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => ref.invalidate(discoveryProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Scan'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: discoveredAsync.when(
                    data: (devices) => _DeviceList(devices: devices),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Discovery error: $err',
                              style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => ref.invalidate(discoveryProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(),
                // Saved devices
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Saved TVs',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: savedAsync.when(
                    data: (devices) => _DeviceList(devices: devices),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) =>
                        const Center(child: Text('No saved devices')),
                  ),
                ),
              ],
            ),
          ),
          // Loading overlay
          if (connectingDevice != null)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Connecting...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
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
      builder: (ctx) {
        var isLoading = false;
        String? errorMessage;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Add TV manually'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ipController,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    labelText: 'IP Address',
                    hintText: '192.168.x.x',
                  ),
                  keyboardType:
                      TextInputType.numberWithOptions(decimal: true),
                ),
                if (isLoading) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed:
                    isLoading ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final ip = ipController.text.trim();
                        if (ip.isEmpty) return;
                        setState(() {
                          isLoading = true;
                          errorMessage = null;
                        });
                        try {
                          final device = TvDeviceInfo(
                            name: 'Panasonic TV ($ip)',
                            ipAddress: ip,
                            brand: TvBrand.panasonic,
                          );
                          await ref.read(connectToDeviceProvider)(
                              device);
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          setState(() {
                            isLoading = false;
                            errorMessage =
                                'Connection failed: ${e.toString().replaceFirst("Exception: ", "")}';
                          });
                        }
                      },
                child: const Text('Connect'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DeviceList extends ConsumerWidget {
  final List<TvDeviceInfo> devices;

  const _DeviceList({required this.devices});

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

    final deleteDevice = ref.watch(deleteDeviceProvider);
    final renameDevice = ref.watch(renameDeviceProvider);

    return ListView.builder(
      itemCount: devices.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final device = devices[index];
        return Dismissible(
          key: Key('saved_${device.ipAddress}_${device.port}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            return true;
          },
          onDismissed: (_) => deleteDevice(device),
          child: Card(
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
                ref.read(connectToDeviceProvider)(device).catchError((_) {});
              },
              onLongPress: () => _showRenameDialog(
                  context, device, renameDevice),
            ),
          ),
        );
      },
    );
  }
}

void _showRenameDialog(
  BuildContext context,
  TvDeviceInfo device,
  Future<void> Function(TvDeviceInfo, String) renameDevice,
) {
  final nameController = TextEditingController(text: device.name);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Rename TV'),
      content: TextField(
        controller: nameController,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Name',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final newName = nameController.text.trim();
            if (newName.isEmpty) return;
            renameDevice(device, newName);
            Navigator.pop(ctx);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
