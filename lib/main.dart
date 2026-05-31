import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'domain/models/tv_device_info.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: TvRemoteApp(),
    ),
  );
}

/// Attempts auto-reconnect to the last connected TV on app startup.
Future<TvDeviceInfo?> loadLastDevice() async {
  final prefs = await SharedPreferences.getInstance();
  final json = prefs.getString('last_connected');
  if (json == null) return null;
  try {
    return TvDeviceInfo.fromJson(jsonDecode(json) as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
}
