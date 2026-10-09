import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_driver_app/features/availability/application/offer_countdown.dart';

void main() {
  group('offer countdown', () {
    test('uses server expiresAt with zero skew', () {
      final expires = DateTime.parse('2026-10-09T12:00:30.000Z');
      final now = DateTime.parse('2026-10-09T12:00:10.000Z');
      expect(
        remainingUntilExpiry(expiresAtUtc: expires, localNowUtc: now),
        const Duration(seconds: 20),
      );
      expect(
        isOfferExpiredByServer(expiresAtUtc: expires, localNowUtc: now),
        isFalse,
      );
    });

    test('tolerates local clock ahead via skew', () {
      final expires = DateTime.parse('2026-10-09T12:00:30.000Z');
      // Local clock 5s ahead of server.
      final localNow = DateTime.parse('2026-10-09T12:00:25.000Z');
      const skewMs = 5000;
      expect(
        remainingUntilExpiry(
          expiresAtUtc: expires,
          localNowUtc: localNow,
          serverSkewMs: skewMs,
        ),
        const Duration(seconds: 10),
      );
    });

    test('marks expired at authoritative boundary', () {
      final expires = DateTime.parse('2026-10-09T12:00:30.000Z');
      final now = DateTime.parse('2026-10-09T12:00:30.000Z');
      expect(
        isOfferExpiredByServer(expiresAtUtc: expires, localNowUtc: now),
        isTrue,
      );
      expect(formatCountdown(Duration.zero), '00:00');
    });

    test('formatCountdown pads mm:ss', () {
      expect(formatCountdown(const Duration(seconds: 75)), '01:15');
      expect(formatCountdown(const Duration(seconds: 9)), '00:09');
    });

    test('estimateServerSkewMs from HTTP Date sample', () {
      final local = DateTime.parse('2026-10-09T12:00:10.000Z');
      final server = DateTime.parse('2026-10-09T12:00:05.000Z');
      expect(
        estimateServerSkewMs(localSampleUtc: local, serverSampleUtc: server),
        5000,
      );
      expect(
        estimateServerSkewMs(localSampleUtc: local, serverSampleUtc: null),
        0,
      );
    });
  });
}
