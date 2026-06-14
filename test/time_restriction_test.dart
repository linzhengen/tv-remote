import 'package:flutter_test/flutter_test.dart';
import 'package:tv_remote/domain/models/time_restriction.dart';

void main() {
  group('TimeRestriction.isAllowed', () {
    test('disabled restriction always allows', () {
      const restriction = TimeRestriction(
        enabled: false,
        startHour: 6,
        startMinute: 0,
        endHour: 21,
        endMinute: 0,
      );
      expect(restriction.isAllowed(DateTime(2026, 1, 1, 12, 0)), isTrue);
      expect(restriction.isAllowed(DateTime(2026, 1, 1, 3, 0)), isTrue);
      expect(restriction.isAllowed(DateTime(2026, 1, 1, 23, 0)), isTrue);
    });

    group('normal range (06:00-21:00)', () {
      const restriction = TimeRestriction(
        enabled: true,
        startHour: 6,
        startMinute: 0,
        endHour: 21,
        endMinute: 0,
      );

      test('inside range allows', () {
        expect(restriction.isAllowed(DateTime(2026, 1, 1, 12, 0)), isTrue);
      });

      test('before range blocks', () {
        expect(restriction.isAllowed(DateTime(2026, 1, 1, 3, 0)), isFalse);
      });

      test('after range blocks', () {
        expect(restriction.isAllowed(DateTime(2026, 1, 1, 23, 0)), isFalse);
      });

      test('exact start boundary', () {
        expect(restriction.isAllowed(DateTime(2026, 1, 1, 6, 0)), isTrue);
      });

      test('exact end boundary', () {
        expect(restriction.isAllowed(DateTime(2026, 1, 1, 21, 0)), isTrue);
      });

      test('one minute before start', () {
        expect(restriction.isAllowed(DateTime(2026, 1, 1, 5, 59)), isFalse);
      });

      test('one minute after end', () {
        expect(restriction.isAllowed(DateTime(2026, 1, 1, 21, 1)), isFalse);
      });
    });

    group('overnight range (22:00-06:00)', () {
      const restriction = TimeRestriction(
        enabled: true,
        startHour: 22,
        startMinute: 0,
        endHour: 6,
        endMinute: 0,
      );

      test('inside overnight (late night) allows', () {
        expect(restriction.isAllowed(DateTime(2026, 1, 1, 23, 0)), isTrue);
      });

      test('inside overnight (early morning) allows', () {
        expect(restriction.isAllowed(DateTime(2026, 1, 1, 3, 0)), isTrue);
      });

      test('outside overnight (afternoon) blocks', () {
        expect(restriction.isAllowed(DateTime(2026, 1, 1, 12, 0)), isFalse);
      });

      test('exact start boundary (22:00)', () {
        expect(restriction.isAllowed(DateTime(2026, 1, 1, 22, 0)), isTrue);
      });

      test('exact end boundary (06:00)', () {
        expect(restriction.isAllowed(DateTime(2026, 1, 1, 6, 0)), isTrue);
      });

      test('one minute before start (21:59)', () {
        expect(restriction.isAllowed(DateTime(2026, 1, 1, 21, 59)), isFalse);
      });

      test('one minute after end (06:01)', () {
        expect(restriction.isAllowed(DateTime(2026, 1, 1, 6, 1)), isFalse);
      });
    });
  });

  group('TimeRestriction JSON serialization', () {
    test('round-trip preserves all fields', () {
      const original = TimeRestriction(
        enabled: true,
        startHour: 7,
        startMinute: 30,
        endHour: 22,
        endMinute: 45,
      );
      final json = original.toJson();
      final restored = TimeRestriction.fromJson(json);
      expect(restored.enabled, original.enabled);
      expect(restored.startHour, original.startHour);
      expect(restored.startMinute, original.startMinute);
      expect(restored.endHour, original.endHour);
      expect(restored.endMinute, original.endMinute);
    });

    test('fromJson provides defaults for missing fields', () {
      final restored = TimeRestriction.fromJson(<String, dynamic>{});
      expect(restored.enabled, false);
      expect(restored.startHour, 6);
      expect(restored.startMinute, 0);
      expect(restored.endHour, 21);
      expect(restored.endMinute, 0);
    });

    test('TimeRestriction.defaults is disabled', () {
      final defaults = TimeRestriction.defaults();
      expect(defaults.enabled, isFalse);
      expect(defaults.isAllowed(DateTime(2026, 1, 1, 3, 0)), isTrue);
    });
  });
}
