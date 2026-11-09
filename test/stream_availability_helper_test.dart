import 'package:flutter_test/flutter_test.dart';
import 'package:shoot_live/core/utils/stream_availability_helper.dart';
import 'package:shoot_live/data/models/match_stream_model.dart';

void main() {
  group('StreamAvailabilityHelper Smart Availability Logic Tests', () {
    final now = DateTime(2026, 9, 22, 20, 0, 0); // 8:00 PM

    test('Test 1: Match starts in 2 hours, no stream -> PRE_MATCH_WAITING', () {
      final kickoff = now.add(const Duration(hours: 2)); // 10:00 PM

      final result = StreamAvailabilityHelper.evaluate(
        streamModel: null,
        kickoffDateTime: kickoff,
        now: now,
      );

      expect(result.state, equals(StreamAvailabilityState.preMatchWaiting));
      expect(result.remainingTime, equals(const Duration(hours: 2)));

      final naturalArabic = StreamAvailabilityHelper.formatNaturalArabicCountdown(result.remainingTime!);
      expect(naturalArabic, equals('٢ ساعات'));

      final naturalArabic2 = StreamAvailabilityHelper.formatNaturalArabicCountdown(
        const Duration(hours: 1, minutes: 24),
      );
      expect(naturalArabic2, equals('ساعة و ٢٤ دقيقة'));
    });

    test('Test 2: Match starts in 3 minutes, no stream -> PREPARING_STREAM', () {
      final kickoff = now.add(const Duration(minutes: 3)); // 8:03 PM

      final result = StreamAvailabilityHelper.evaluate(
        streamModel: null,
        kickoffDateTime: kickoff,
        now: now,
      );

      expect(result.state, equals(StreamAvailabilityState.preparingStream));
      expect(result.remainingTime, equals(const Duration(minutes: 3)));
    });

    test('Test 3: Match started 10 minutes ago, no stream -> MATCH_STARTED_NO_STREAM', () {
      final kickoff = now.subtract(const Duration(minutes: 10)); // 7:50 PM

      final result = StreamAvailabilityHelper.evaluate(
        streamModel: null,
        kickoffDateTime: kickoff,
        now: now,
        isLive: true,
      );

      expect(result.state, equals(StreamAvailabilityState.matchStartedNoStream));
    });

    test('Test 4: Match starts in 2 hours, active stream exists -> STREAM_AVAILABLE', () {
      final kickoff = now.add(const Duration(hours: 2));

      final activeStreamModel = MatchStreamModel(
        matchId: 101,
        isEnabled: true,
        servers: [
          const StreamServerModel(
            id: 's1',
            name: 'Server 1 HD',
            streamUrl: 'https://example.com/live.m3u8',
            playerType: PlayerType.hls,
            isActive: true,
            priority: 1,
          ),
        ],
      );

      final result = StreamAvailabilityHelper.evaluate(
        streamModel: activeStreamModel,
        kickoffDateTime: kickoff,
        now: now,
      );

      expect(result.state, equals(StreamAvailabilityState.streamAvailable));
    });

    test('Test 5: Stream added while waiting -> Real-time state transition from PRE_MATCH_WAITING to STREAM_AVAILABLE', () {
      final kickoff = now.add(const Duration(hours: 1));

      // Initial state: No stream document in Firestore
      final initialResult = StreamAvailabilityHelper.evaluate(
        streamModel: null,
        kickoffDateTime: kickoff,
        now: now,
      );
      expect(initialResult.state, equals(StreamAvailabilityState.preMatchWaiting));

      // Simulator: Administrator adds a stream in Dashboard & Firestore updates snapshot
      final updatedStreamModel = MatchStreamModel(
        matchId: 202,
        isEnabled: true,
        servers: [
          const StreamServerModel(
            id: 'srv_live',
            name: 'Server 1 - Live',
            streamUrl: 'https://example.com/hls/live.m3u8',
            playerType: PlayerType.hls,
            isActive: true,
            priority: 1,
          ),
        ],
      );

      final updatedResult = StreamAvailabilityHelper.evaluate(
        streamModel: updatedStreamModel,
        kickoffDateTime: kickoff,
        now: now,
      );

      expect(updatedResult.state, equals(StreamAvailabilityState.streamAvailable));
    });
  });
}
