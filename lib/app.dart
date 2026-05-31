import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'main.dart' show loadLastDevice;
import 'presentation/providers/tv_provider.dart';
import 'presentation/screens/discovery_screen.dart';
import 'presentation/screens/remote_screen.dart';

final autoReconnectProvider = FutureProvider<void>((ref) async {
  final device = await loadLastDevice();
  if (device == null) return;
  // Trigger connection attempt — on success, currentDeviceProvider
  // and tvControllerProvider are set by connectToDeviceProvider.
  try {
    await ref.read(connectToDeviceProvider(device).future);
  } catch (_) {
    // Connection failed — stay on discovery screen
  }
});

class TvRemoteApp extends ConsumerWidget {
  const TvRemoteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(currentDeviceProvider);
    // Trigger auto-reconnect on first build
    ref.watch(autoReconnectProvider);

    return MaterialApp(
      title: 'TV Remote',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: device != null ? const RemoteScreen() : const DiscoveryScreen(),
    );
  }
}
