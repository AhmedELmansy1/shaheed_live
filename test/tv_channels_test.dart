import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoot_live/core/theme/app_colors.dart';
import 'package:shoot_live/core/theme/app_theme.dart';
import 'package:shoot_live/data/models/theme_config_model.dart';
import 'package:shoot_live/data/models/tv_channel_model.dart';
import 'package:shoot_live/data/repositories/tv_channels_repository.dart';
import 'package:shoot_live/presentation/channels/channels_screen.dart';
import 'package:shoot_live/presentation/home/widgets/quick_tv_channels_strip.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TvChannelModel Unit Tests', () {
    test('1. Deserializes from Map correctly with complete fields', () {
      final map = {
        'name': 'beIN Sports 1 Premium',
        'logo_url': 'https://example.com/bein1.png',
        'default_stream_url': 'https://example.com/stream.m3u8',
        'default_player_type': 'hls',
        'default_quality': 'fhd',
        'is_active': true,
        'order': 5,
      };

      final model = TvChannelModel.fromMap(map, 'doc_123');
      expect(model.id, equals('doc_123'));
      expect(model.name, equals('beIN Sports 1 Premium'));
      expect(model.logoUrl, equals('https://example.com/bein1.png'));
      expect(model.defaultStreamUrl, equals('https://example.com/stream.m3u8'));
      expect(model.defaultPlayerType, equals(TvPlayerType.hls));
      expect(model.defaultQuality, equals('fhd'));
      expect(model.qualityBadge, equals('FHD'));
      expect(model.isActive, isTrue);
      expect(model.order, equals(5));
    });

    test('2. Handles missing/null fields and embeds gracefully', () {
      final map = {
        'name': '',
        'default_player_type': 'embed',
        'default_quality': 'unknown',
        'order': '3',
      };

      final model = TvChannelModel.fromMap(map, 'doc_embed');
      expect(model.id, equals('doc_embed'));
      expect(model.name, equals('قناة رياضية')); // Default fallback name
      expect(model.defaultPlayerType, equals(TvPlayerType.embed));
      expect(model.defaultQuality, equals('unknown'));
      expect(model.qualityBadge, equals('HD')); // Fallback badge
      expect(model.order, equals(3));
      expect(model.isActive, isTrue);
    });

    test('3. Serializes to map round-trip preserves all data', () {
      const original = TvChannelModel(
        id: 'ssc_extra_1',
        name: 'SSC Extra 1 HD',
        logoUrl: 'https://example.com/ssc.png',
        defaultStreamUrl: 'https://example.com/ssc.m3u8',
        defaultPlayerType: TvPlayerType.hls,
        defaultQuality: 'hd',
        isActive: false,
        order: 10,
      );

      final map = original.toMap();
      final restored = TvChannelModel.fromMap(map, original.id);
      expect(restored, equals(original));
    });
  });

  group('TvChannelsRepository Cache & Fallback Tests', () {
    test('1. Returns default channels when local cache is empty', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = TvChannelsRepository(prefs: prefs);

      final channels = await repo.getCachedChannels();
      expect(channels, isNotEmpty);
      expect(channels.length, equals(TvChannelModel.defaultChannels.length));
      expect(channels.first.name, equals('beIN Sports 1 HD'));
    });

    test('2. Streams initial cache and sorts by order ascending', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = TvChannelsRepository(prefs: prefs);

      final list = await repo.listenToChannels().first;
      expect(list.length, greaterThanOrEqualTo(4));
      // Verify sorted by order ascending
      for (var i = 0; i < list.length - 1; i++) {
        expect(list[i].order <= list[i + 1].order, isTrue);
      }
    });
  });

  group('ThemeConfigModel Seasonal Dark Fix Test', () {
    test('defaultDark preset returns AppThemeColors.dark without emerald override', () {
      const config = ThemeConfigModel(
        preset: SeasonalPreset.defaultDark,
        primaryColor: Color(0xFF10B981), // Dashboard emerald green
        accentColor: Color(0xFFF59E0B),
        enabled: true,
      );

      final themeColors = config.toThemeColors(isDark: true);
      // It must be dark theme's primary (electric blue), NOT emerald green!
      expect(themeColors.primary, equals(AppThemeColors.dark.primary));
      expect(themeColors.primary, isNot(equals(const Color(0xFF10B981))));
    });
  });

  group('TV Channels Widget Tests', () {
    testWidgets('Renders ChannelsScreen and displays channels catalog', (tester) async {
      final fakeChannels = [
        const TvChannelModel(
          id: 'test_ch_1',
          name: 'قناة الكأس 1',
          defaultStreamUrl: 'https://example.com/alkass.m3u8',
          defaultPlayerType: TvPlayerType.hls,
          defaultQuality: 'fhd',
          isActive: true,
          order: 1,
        ),
        const TvChannelModel(
          id: 'test_ch_2',
          name: 'قناة دبي الرياضية',
          defaultStreamUrl: 'https://example.com/dubai.m3u8',
          defaultPlayerType: TvPlayerType.embed,
          defaultQuality: 'hd',
          isActive: true,
          order: 2,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tvChannelsStreamProvider.overrideWith((ref) => Stream.value(fakeChannels)),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const Directionality(
              textDirection: TextDirection.rtl,
              child: ChannelsScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header title and count
      expect(find.text('قنوات البث المباشر'), findsOneWidget);
      expect(find.text('2 قنوات'), findsOneWidget);

      // Check channel names
      expect(find.text('قناة الكأس 1'), findsOneWidget);
      expect(find.text('قناة دبي الرياضية'), findsOneWidget);

      // Check quality badges
      expect(find.text('FHD'), findsWidgets);
      expect(find.text('HD'), findsWidgets);
    });

    testWidgets('Renders QuickTvChannelsStrip and reacts to channels', (tester) async {
      final fakeChannels = [
        const TvChannelModel(
          id: 'quick_ch_1',
          name: 'أون تايم سبورتس 1',
          defaultStreamUrl: 'https://example.com/ontime.m3u8',
          defaultPlayerType: TvPlayerType.hls,
          defaultQuality: 'hd',
          isActive: true,
          order: 1,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tvChannelsStreamProvider.overrideWith((ref) => Stream.value(fakeChannels)),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(
              body: Directionality(
                textDirection: TextDirection.rtl,
                child: QuickTvChannelsStrip(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('قنوات البث المباشر'), findsOneWidget);
      expect(find.text('عرض الكل'), findsOneWidget);
      expect(find.text('أون تايم سبورتس 1'), findsOneWidget);
    });
  });
}

