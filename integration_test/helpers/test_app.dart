import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_remote/app.dart';
import 'package:tv_remote/domain/models/time_restriction.dart';
import 'package:tv_remote/presentation/providers/tv_provider.dart';

import 'mock_tv_controller.dart';

MockTvController get mockController => _mock!;
MockTvController? _mock;

/// Prepares mock controller instance.
void setUpTestApp(MockTvController mock) {
  _mock = mock;
}

/// Builds the app with all external dependencies mocked.
Widget buildTestApp() {
  return ProviderScope(
    overrides: [
      // Inject mock controller factory
      controllerFactoryProvider.overrideWith((ref) {
        return (_) => _mock!;
      }),
      // Prevent real SSDP network discovery
      timeRestrictionProvider.overrideWith((ref) async => TimeRestriction.defaults()),
      scanNetworkProvider.overrideWith((ref) => () async {}),
      // Prevent SharedPreferences read (returns empty)
      savedDevicesProvider.overrideWith((ref) async => []),
    ],
    child: const TvRemoteApp(),
  );
}

/// Pumps the test app and waits for the initial build to settle.
///
/// Uses [tester.pump] with explicit duration instead of [tester.pumpAndSettle]
/// because SSDP discovery timers prevent auto-settling.
Future<void> pumpTestApp(WidgetTester tester, MockTvController mock) async {
  // Set a generous surface size to avoid layout overflows in tests
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  setUpTestApp(mock);
  await tester.pumpWidget(buildTestApp());
  // Allow async init (auto-reconnect) and initial build to complete
  await tester.pump(const Duration(seconds: 1));
}
