import 'package:flutter_test/flutter_test.dart';
import 'package:tv_remote/domain/models/tv_device_info.dart';

void main() {
  group('TvDeviceInfo', () {
    test('toJson and fromJson round-trip', () {
      final device = const TvDeviceInfo(
        name: 'Test TV',
        ipAddress: '192.168.1.100',
        brand: TvBrand.panasonic,
        modelName: 'TX-50',
        port: 55000,
      );

      final json = device.toJson();
      final restored = TvDeviceInfo.fromJson(json);

      expect(restored.name, 'Test TV');
      expect(restored.ipAddress, '192.168.1.100');
      expect(restored.brand, TvBrand.panasonic);
      expect(restored.modelName, 'TX-50');
      expect(restored.port, 55000);
    });

    test('equality is based on ipAddress and port', () {
      const a = TvDeviceInfo(
        name: 'A',
        ipAddress: '192.168.1.1',
        brand: TvBrand.panasonic,
        port: 55000,
      );
      const b = TvDeviceInfo(
        name: 'B',
        ipAddress: '192.168.1.1',
        brand: TvBrand.samsung,
        port: 55000,
      );
      const c = TvDeviceInfo(
        name: 'A',
        ipAddress: '192.168.1.1',
        brand: TvBrand.panasonic,
        port: 55001,
      );

      expect(a, b); // same ip+port
      expect(a, isNot(c)); // different port
    });

    test('fromJson defaults port to 55000', () {
      final device = TvDeviceInfo.fromJson({
        'name': 'TV',
        'ipAddress': '192.168.1.1',
        'brand': 'lg',
      });
      expect(device.port, 55000);
    });
  });
}
