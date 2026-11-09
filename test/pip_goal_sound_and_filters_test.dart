import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoot_live/core/services/pip_service.dart';
import 'package:shoot_live/data/models/match_model.dart';
import 'package:shoot_live/data/models/team_model.dart';
import 'package:shoot_live/presentation/home/providers/matches_provider.dart';
import 'package:shoot_live/presentation/settings/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Safe Match Parsing & Favorite Matching Invariants', () {
    test('Empty team names fallback cleanly to "فريق غير محدد" and non-empty string', () {
      final raw = {
        'match_id': 9999,
        'home_team': {'row_id': 100, 'title': ''},
        'away_team': {'row_id': 200, 'title': '   '},
        'championship': {'id': 1, 'title': 'كأس مصر'},
      };

      final match = MatchModel.fromMap(raw);
      expect(match.homeTeam.title, 'فريق غير محدد');
      expect(match.awayTeam.title, 'فريق غير محدد');
      expect(match.homeTeam.title.isNotEmpty, isTrue);
      expect(match.awayTeam.title.isNotEmpty, isTrue);
    });

    test('Match with empty or fallback team title does NOT match user favorite teams', () {
      final raw = {
        'match_id': 9999,
        'home_team': {'row_id': 100, 'title': ''},
        'away_team': {'row_id': 200, 'title': ''},
        'championship': {'id': 1, 'title': 'كأس مصر'},
      };

      final match = MatchModel.fromMap(raw);
      final followedTeamIds = ['8650', 'ahly'];
      final List<TeamModel> allTeams = [
        const TeamModel(id: '8650', name: 'ليفربول', nameEn: 'Liverpool', leagueId: '1'),
        const TeamModel(id: 'ahly', name: 'الأهلي', nameEn: 'Al Ahly', leagueId: '1'),
      ];

      final isFav = isFavoriteTeamMatch(match, followedTeamIds, allTeams);
      expect(isFav, isFalse, reason: 'Empty team names must NEVER match user favorites');
    });

    test('Match with home_name and away_name at root extracts correctly as fallback', () {
      final raw = {
        'match_id': 8888,
        'home_name': 'الزمالك',
        'away_name': 'بيراميدز',
        'championship': {'id': 1, 'title': 'الدوري المصري الممتاز'},
      };

      final match = MatchModel.fromMap(raw);
      expect(match.homeTeam.title, 'الزمالك');
      expect(match.awayTeam.title, 'بيراميدز');
    });
  });

  group('Picture-in-Picture (PiP) Service Tests', () {
    test('isPipSupported delegates to MethodChannel and handles platform responses', () async {
      const channel = MethodChannel('com.livepulse.scores/pip');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'isPipSupported') return true;
        if (call.method == 'enterPip') return true;
        if (call.method == 'setAutoPip') return null;
        return null;
      });

      final isSupported = await PipService.isPipSupported();
      expect(isSupported, isTrue);

      final entered = await PipService.enterPip();
      expect(entered, isTrue);

      // Clean up
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
  });

  group('Custom Goal Sounds Settings Tests', () {
    test('Defaults to whistle and persists selected goal alert sound', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initial = container.read(notificationSettingsProvider);
      expect(initial.goalSound, 'whistle');

      await container.read(notificationSettingsProvider.notifier).setGoalSound('cheer');
      final updated = container.read(notificationSettingsProvider);
      expect(updated.goalSound, 'cheer');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pref_notify_goal_sound'), 'cheer');
    });
  });

  group('Channel & Commentator Quick Filter Tests', () {
    test('ChannelFilterNotifier and CommentatorFilterNotifier update state properly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedChannelFilterProvider), isNull);
      expect(container.read(selectedCommentatorFilterProvider), isNull);

      container.read(selectedChannelFilterProvider.notifier).setChannel('beIN Sports 1 HD');
      expect(container.read(selectedChannelFilterProvider), 'beIN Sports 1 HD');

      container.read(selectedCommentatorFilterProvider.notifier).setCommentator('عصام الشوالي');
      expect(container.read(selectedCommentatorFilterProvider), 'عصام الشوالي');

      container.read(selectedChannelFilterProvider.notifier).setChannel(null);
      expect(container.read(selectedChannelFilterProvider), isNull);
    });
  });
}
