import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shoot_live/core/routing/deep_link_handler.dart';
import 'package:shoot_live/core/services/stream_report_service.dart';
import 'package:shoot_live/core/theme/app_colors.dart';
import 'package:shoot_live/core/utils/date_formatter.dart';
import 'package:shoot_live/data/models/poll_model.dart';
import 'package:shoot_live/data/models/sponsorship_model.dart';
import 'package:shoot_live/data/models/theme_config_model.dart';

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('Step 2 — 6 Dashboard Features Tests', () {
    // -------------------------------------------------------------
    // Feature 1 & 2: Remote Theme & Kickoff Offset
    // -------------------------------------------------------------
    group('1 & 2: Remote Theme & Kickoff Offset', () {
      test('ThemeConfigModel parses nested theme_config and clamps offset', () {
        final rawMap = {
          'theme_config': {
            'active_preset': 'ramadan',
            'primary_color': '#8B5CF6',
            'accent_color': '#F59E0B',
            'banner_url': 'https://example.com/ramadan.png',
            'enabled': true,
            'kickoff_offset_hours': 5, // Above +3, must clamp
          },
        };

        final config = ThemeConfigModel.fromMap(rawMap);
        expect(config.preset, SeasonalPreset.ramadan);
        expect(config.primaryColor, const Color(0xFF8B5CF6));
        expect(config.accentColor, const Color(0xFFF59E0B));
        expect(config.kickoffOffsetHours, 3); // Clamped to 3
        expect(config.enabled, isTrue);
      });

      test('ThemeConfigModel falls back to root kickoff_offset_hours if nested is absent', () {
        final rawMap = {
          'kickoff_offset_hours': -2,
          'theme_config': {
            'active_preset': 'champions_league',
            'enabled': true,
          },
        };

        final config = ThemeConfigModel.fromMap(rawMap);
        expect(config.preset, SeasonalPreset.championsLeague);
        expect(config.kickoffOffsetHours, -2);
      });

      test('WCAG contrast validator correctly verifies AA standard (>= 4.5:1)', () {
        // High contrast pair: white text on dark vermilion #FF5A3C -> check contrast
        final whiteOnDark = WcagHelper.computeContrastRatio(Colors.white, const Color(0xFF0E1015));
        expect(whiteOnDark, greaterThan(15.0));
        expect(WcagHelper.meetsWcagAA(Colors.white, const Color(0xFF0E1015)), isTrue);

        // Low contrast pair: light yellow on white
        final yellowOnWhite = WcagHelper.computeContrastRatio(const Color(0xFFFEF08A), Colors.white);
        expect(yellowOnWhite, lessThan(3.0));
        expect(WcagHelper.meetsWcagAA(const Color(0xFFFEF08A), Colors.white), isFalse);

        // getReadableTextColor picks inkPrimary for bright surfaces
        final onBright = WcagHelper.getReadableTextColor(const Color(0xFFFEF08A));
        expect(onBright, AppColors.lightTextPrimary);
      });

      test('Kickoff offset shifts display time without shifting date tabs', () {
        const rawDate = '2026-11-09';
        const rawTime = '16:00:00';

        // Base time (offset 0)
        final base = DateFormatter.formatMatchTime(rawDate, rawTime, offsetHours: 0);

        // Offset +1 hour (e.g. 16:00 -> 17:00)
        final plusOne = DateFormatter.formatMatchTime(rawDate, rawTime, offsetHours: 1);
        expect(plusOne, isNot(equals(base)));

        // Offset clamped to -3
        final minusThree = DateFormatter.formatMatchTime(rawDate, rawTime, offsetHours: -10);
        final minusThreeExact = DateFormatter.formatMatchTime(rawDate, rawTime, offsetHours: -3);
        expect(minusThree, equals(minusThreeExact));
      });
    });

    // -------------------------------------------------------------
    // Feature 3: Match Polls
    // -------------------------------------------------------------
    group('3: Match Polls', () {
      test('PollModel computes correct percentages and Arabic formatted labels', () {
        final poll = PollModel(
          matchId: '5795507',
          question: 'من سيفوز بالقمة؟',
          options: const [
            PollOption(id: 'opt_1', label: 'كريستال بالاس', votes: 25),
            PollOption(id: 'opt_2', label: 'التعادل', votes: 25),
            PollOption(id: 'opt_3', label: 'ليفربول', votes: 50),
          ],
          totalVotes: 100,
          enabled: true,
        );

        expect(poll.percentageOf(poll.options[0]), 25);
        expect(poll.formattedPercentageOf(poll.options[0]), '25%');

        expect(poll.percentageOf(poll.options[2]), 50);
        expect(poll.formattedPercentageOf(poll.options[2]), '50%');

        expect(poll.hasUserVoted, isFalse);
        final votedPoll = poll.copyWith(userVotedOptionId: 'opt_3');
        expect(votedPoll.hasUserVoted, isTrue);
      });
    });

    // -------------------------------------------------------------
    // Feature 4: Direct Sponsorships
    // -------------------------------------------------------------
    group('4: Direct Sponsorships', () {
      test('SponsorshipCampaign accurately checks active date windows and placements', () {
        final today = DateTime.now().toIso8601String().split('T')[0];

        final activeCampaign = SponsorshipCampaign(
          id: 'camp_1',
          title: 'عرض ترويجي',
          sponsorName: 'STC',
          bannerUrl: 'https://example.com/banner.png',
          clickUrl: 'https://stc.com',
          placement: SponsorshipPlacement.homeTopBanner,
          startDate: today,
          endDate: today,
          enabled: true,
        );
        expect(activeCampaign.isActive, isTrue);

        final expiredCampaign = SponsorshipCampaign(
          id: 'camp_2',
          title: 'حملة منتهية',
          sponsorName: 'قديم',
          bannerUrl: 'https://example.com/old.png',
          clickUrl: '',
          placement: SponsorshipPlacement.matchDetailsTop,
          startDate: '2020-01-01',
          endDate: '2020-01-02',
          enabled: true,
        );
        expect(expiredCampaign.isActive, isFalse);

        final disabledCampaign = activeCampaign.copyWithDisabled();
        expect(disabledCampaign.isActive, isFalse);
      });
    });

    // -------------------------------------------------------------
    // Feature 5: Stream Issue Reports
    // -------------------------------------------------------------
    group('5: Stream Issue Reports', () {
      test('StreamIssueType enums map to exact required backend keys and Arabic descriptions', () {
        expect(StreamIssueType.buffering.key, 'buffering');
        expect(StreamIssueType.offline.key, 'offline');
        expect(StreamIssueType.wrongMatch.key, 'wrong_match');
        expect(StreamIssueType.noAudio.key, 'no_audio');
        expect(StreamIssueType.badQuality.key, 'bad_quality');

        for (final issue in StreamIssueType.values) {
          expect(issue.arabicLabel.isNotEmpty, isTrue);
        }
      });
    });

    // -------------------------------------------------------------
    // Feature 6: Deep Links Handling
    // -------------------------------------------------------------
    group('6: Deep Links Ingestion', () {
      test('DeepLinkHandler extracts match IDs from custom scheme and web URLs', () {
        // Custom scheme: shootlive://match/5795507
        final uri1 = Uri.parse('shootlive://match/5795507');
        expect(DeepLinkHandler.extractMatchId(uri1), '5795507');

        // Custom scheme query: shootlive://match?id=5795507
        final uri2 = Uri.parse('shootlive://match?id=5795507');
        expect(DeepLinkHandler.extractMatchId(uri2), '5795507');

        // Web URL: https://shootlive.app/match/5795507
        final uri3 = Uri.parse('https://shootlive.app/match/5795507');
        expect(DeepLinkHandler.extractMatchId(uri3), '5795507');

        // Web URL query: https://shootlive.app/match?match_id=5795507
        final uri4 = Uri.parse('https://shootlive.app/match?match_id=5795507');
        expect(DeepLinkHandler.extractMatchId(uri4), '5795507');

        // Invalid link
        final uri5 = Uri.parse('https://shootlive.app/about');
        expect(DeepLinkHandler.extractMatchId(uri5), isNull);
      });
    });
  });
}

extension on SponsorshipCampaign {
  SponsorshipCampaign copyWithDisabled() {
    return SponsorshipCampaign(
      id: id,
      title: title,
      sponsorName: sponsorName,
      bannerUrl: bannerUrl,
      clickUrl: clickUrl,
      placement: placement,
      startDate: startDate,
      endDate: endDate,
      enabled: false,
    );
  }
}
