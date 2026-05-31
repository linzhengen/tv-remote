import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tv_remote/domain/models/remote_command.dart';

import 'helpers/mock_tv_controller.dart';
import 'helpers/screens.dart';
import 'helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockTvController mock;

  setUp(() async {
    // Reset SharedPreferences between tests to prevent state leakage
    SharedPreferences.setMockInitialValues({});
    mock = MockTvController();
    mock.commandDelay = Duration.zero;
  });

  group('Discovery screen', () {
    testWidgets('shows empty state on first launch', (tester) async {
      await pumpTestApp(tester, mock);
      final screen = DiscoveryScreenHelper(tester);

      expect(screen.appBar, findsOneWidget);
      expect(screen.scanButton, findsOneWidget);
      expect(screen.nearbyHeader, findsOneWidget);
      expect(screen.savedHeader, findsOneWidget);
      expect(screen.noDevicesText, findsNWidgets(2));
      expect(screen.addButton, findsOneWidget);
    });

    testWidgets('manual add dialog opens and can be cancelled', (tester) async {
      await pumpTestApp(tester, mock);
      final screen = DiscoveryScreenHelper(tester);

      await screen.openAddDialog('192.168.1.100');
      await screen.tapCancel();

      expect(screen.appBar, findsOneWidget);
    });
  });

  group('Connect flow', () {
    testWidgets('manual connect navigates to remote screen', (tester) async {
      await pumpTestApp(tester, mock);
      final discovery = DiscoveryScreenHelper(tester);

      await discovery.openAddDialog('192.168.1.100');
      await discovery.tapConnect();

      // Should show remote screen (AppBar with device name)
      expect(find.text('Panasonic TV (192.168.1.100)'), findsOneWidget);
      expect(mock.lastConnectedDevice?.ipAddress, '192.168.1.100');
    });

    testWidgets('remote screen shows power button in AppBar', (tester) async {
      await pumpTestApp(tester, mock);
      final discovery = DiscoveryScreenHelper(tester);

      await discovery.openAddDialog('192.168.1.100');
      await discovery.tapConnect();

      final remote = RemoteScreenHelper(tester);
      expect(remote.powerButton, findsOneWidget);
    });

    testWidgets('power button sends power command to TV', (tester) async {
      await pumpTestApp(tester, mock);
      final discovery = DiscoveryScreenHelper(tester);

      await discovery.openAddDialog('192.168.1.100');
      await discovery.tapConnect();

      final remote = RemoteScreenHelper(tester);
      await remote.tapPower();

      expect(mock.sentCommands, contains(RemoteCommand.power));
    });

    testWidgets('disconnect returns to discovery screen', (tester) async {
      await pumpTestApp(tester, mock);
      final discovery = DiscoveryScreenHelper(tester);

      await discovery.openAddDialog('192.168.1.100');
      await discovery.tapConnect();

      final remote = RemoteScreenHelper(tester);
      await remote.tapDisconnect();

      // Back on discovery screen
      expect(discovery.appBar, findsOneWidget);
    });
  });

  group('Error handling', () {
    testWidgets('stays on discovery screen when connection fails', (tester) async {
      mock.connectResult = false;
      await pumpTestApp(tester, mock);
      final discovery = DiscoveryScreenHelper(tester);

      await discovery.openAddDialog('192.168.1.100');
      await discovery.tapConnect();

      // Should still be on discovery screen
      expect(discovery.appBar, findsOneWidget);
    });

    testWidgets('shows error snackbar on command failure', (tester) async {
      mock.commandError = Exception('TV unreachable');
      mock.failAfterCommands = 0;
      await pumpTestApp(tester, mock);
      final discovery = DiscoveryScreenHelper(tester);

      await discovery.openAddDialog('192.168.1.100');
      await discovery.tapConnect();

      final remote = RemoteScreenHelper(tester);
      await remote.tapPower();

      // Should show error snackbar
      expect(find.textContaining('Command failed'), findsOneWidget);
    });
  });
}
