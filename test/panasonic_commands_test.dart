import 'package:flutter_test/flutter_test.dart';
import 'package:tv_remote/domain/models/remote_command.dart';
import 'package:tv_remote/data/manufacturers/panasonic/panasonic_commands.dart';

void main() {
  group('PanasonicCommands', () {
    test('maps all commands to valid NRC keys without errors', () {
      for (final command in RemoteCommand.values) {
        final nrcKey = PanasonicCommands.nrcKey(command);
        expect(nrcKey, isNotNull);
        expect(nrcKey, startsWith('NRC_'));
        expect(nrcKey, endsWith('-ONOFF'));
      }
    });

    test('power command maps correctly', () {
      expect(
        PanasonicCommands.nrcKey(RemoteCommand.power),
        'NRC_POWER-ONOFF',
      );
    });

    test('volume up maps correctly', () {
      expect(
        PanasonicCommands.nrcKey(RemoteCommand.volumeUp),
        'NRC_VOLUP-ONOFF',
      );
    });

    test('all numeric commands have correct NRC codes', () {
      for (var i = 0; i <= 9; i++) {
        final command = RemoteCommand.values.firstWhere(
          (c) => c.label == i.toString(),
        );
        expect(PanasonicCommands.nrcKey(command), 'NRC_D$i-ONOFF');
      }
    });
  });
}
