import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Page-object helpers for the Discovery screen.
class DiscoveryScreenHelper {
  const DiscoveryScreenHelper(this.tester);
  final WidgetTester tester;

  Finder get appBar => find.text('TV Remote');
  Finder get scanButton => find.text('Scan');
  Finder get nearbyHeader => find.text('Nearby TVs');
  Finder get savedHeader => find.text('Saved TVs');
  Finder get addButton => find.byType(FloatingActionButton);
  Finder get noDevicesText => find.text('No devices found');

  /// Opens the "Add TV manually" dialog and fills in an IP address.
  Future<void> openAddDialog(String ip) async {
    await tester.tap(addButton);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(find.byType(TextField), ip);
  }

  /// Taps the Connect button in the add dialog.
  Future<void> tapConnect() async {
    await tester.tap(find.text('Connect'));
    await tester.pump(const Duration(seconds: 1));
  }

  /// Taps Cancel in the add dialog.
  Future<void> tapCancel() async {
    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(seconds: 1));
  }
}

/// Page-object helpers for the Remote screen.
class RemoteScreenHelper {
  const RemoteScreenHelper(this.tester);
  final WidgetTester tester;

  /// Finds the power button (in AppBar, uses power_settings_new icon).
  Finder get powerButton => find.byIcon(Icons.power_settings_new);

  /// Finds the settings button in AppBar.
  Finder get settingsButton => find.byIcon(Icons.settings);

  /// Finds the close/disconnect button in AppBar.
  Finder get closeButton => find.byIcon(Icons.close);

  /// Taps the power button.
  Future<void> tapPower() async {
    await tester.tap(powerButton);
    await tester.pump(const Duration(seconds: 1));
  }

  /// Taps the close/disconnect button to return to discovery screen.
  Future<void> tapDisconnect() async {
    await tester.tap(closeButton);
    await tester.pump(const Duration(seconds: 1));
  }
}
