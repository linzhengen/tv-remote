import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'main.dart' show loadLastDevice;
import 'presentation/providers/tv_provider.dart';
import 'presentation/screens/discovery_screen.dart';
import 'presentation/screens/remote_screen.dart';

class TvRemoteApp extends ConsumerStatefulWidget {
  const TvRemoteApp({super.key});

  @override
  ConsumerState<TvRemoteApp> createState() => _TvRemoteAppState();
}

class _TvRemoteAppState extends ConsumerState<TvRemoteApp> {
  @override
  void initState() {
    super.initState();
    _autoReconnect();
  }

  Future<void> _autoReconnect() async {
    final device = await loadLastDevice();
    if (device == null || !mounted) return;
    try {
      await ref.read(connectToDeviceProvider)(device);
    } catch (_) {
      // Connection failed — stay on discovery screen
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = ref.watch(currentDeviceProvider);

    return MaterialApp(
      title: 'TV Remote',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: device != null ? const RemoteScreen() : const DiscoveryScreen(),
    );
  }
}
