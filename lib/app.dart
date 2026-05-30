import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'presentation/screens/discovery_screen.dart';

class TvRemoteApp extends StatelessWidget {
  const TvRemoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TV Remote',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const DiscoveryScreen(),
    );
  }
}
