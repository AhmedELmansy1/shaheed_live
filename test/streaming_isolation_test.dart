import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoot_live/core/config/app_constants.dart';
import 'package:shoot_live/core/theme/app_theme.dart';
import 'package:shoot_live/data/models/match_model.dart';
import 'package:shoot_live/data/models/match_stream_model.dart';
import 'package:shoot_live/presentation/match_details/match_details_screen.dart';
import 'package:shoot_live/presentation/match_details/providers/match_stream_provider.dart';
import 'package:shoot_live/presentation/widgets/hero_match_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleMatch = MatchModel(
    matchId: 9901,
    matchDate: '2026-11-08',
    matchTime: '21:00',
    isLive: true,
    status: MatchStatus.live,
    championship: const ChampionshipInfo(id: 1, title: 'الدوري الإنجليزي'),
    homeTeam: const TeamInfo(rowId: 10, title: 'ليفربول'),
    awayTeam: const TeamInfo(rowId: 20, title: 'تشيلسي'),
    homeScore: '1',
    awayScore: '0',
    adminTitle: '٥٥\'',
  );

  group('Streaming Code Isolation & Feature Gate Tests', () {
    test('Default build has compile-time flag ENABLE_STREAMING = false', () {
      expect(
        AppConstants.enableStreaming,
        isFalse,
        reason: 'Public store builds must have streaming disabled by default',
      );
    });

    testWidgets('HeroMatchCard renders "تفاصيل المباراة" button and NO streaming text in default build', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: HeroMatchCard(match: sampleMatch),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Must display match details button
      expect(find.text('تفاصيل المباراة'), findsOneWidget);
      // Must NOT display watch stream button
      expect(find.text('شاهد المباراة الآن ⚽'), findsNothing);
    });

    testWidgets('MatchDetailsScreen hides TV stream action in AppBar even if stream data is present', (tester) async {
      const mockStream = MatchStreamModel(
        matchId: 9901,
        isEnabled: true,
        servers: [
          StreamServerModel(
            id: 'srv_1',
            name: 'سيرفر 1',
            streamUrl: 'https://example.com/hls/test.m3u8',
            playerType: PlayerType.hls,
            priority: 1,
            isActive: true,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchStreamProvider(9901).overrideWith(
              (ref) => Stream.value(mockStream),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: MatchDetailsScreen(
              matchId: sampleMatch.id,
              initialMatch: sampleMatch,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // TV streaming icon must NOT be visible in AppBar
      expect(find.byIcon(Icons.tv_rounded), findsNothing);
    });

    test('matchStreamProvider yields empty stream when enableStreaming is false', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final asyncValue = container.read(matchStreamProvider(9901));
      expect(
        asyncValue.value,
        isNull,
        reason: 'Must not emit stream configuration in default build',
      );
    });
  });
}
