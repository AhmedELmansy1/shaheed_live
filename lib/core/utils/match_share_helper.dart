import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/match_model.dart';
import 'date_formatter.dart';

class MatchShareHelper {
  /// Generates human-friendly Arabic text describing the match status and triggers native share.
  static Future<void> shareMatch(MatchModel match) async {
    final home = match.homeTeam.title;
    final away = match.awayTeam.title;
    final competition = match.championship.title;
    final scoreText = DateFormatter.toArabicNumerals('${match.homeScore ?? 0} - ${match.awayScore ?? 0}');

    String shareText;

    if (match.isLive) {
      final minuteText = match.adminTitle != null && match.adminTitle!.isNotEmpty
          ? DateFormatter.toArabicNumerals(match.adminTitle!)
          : 'مباشر';
      shareText = '🔴 مباشر الآن: $home $scoreText $away - الدقيقة $minuteText | $competition | عبر تطبيق شوت لايف';
    } else if (match.isFinished) {
      shareText = '⚽ النتيجة النهائية: $home $scoreText $away | $competition | عبر تطبيق شوت لايف';
    } else {
      final matchTime = match.formattedLocalTime.isNotEmpty
          ? match.formattedLocalTime
          : (match.matchTime ?? '');
      shareText = '⏰ مباراة $home × $away تبدأ $matchTime | $competition | عبر تطبيق شوت لايف';
    }

    try {
      // ignore: deprecated_member_use
      await Share.share(
        shareText,
        subject: 'مباراة $home × $away - شوت لايف',
      );
    } catch (e) {
      debugPrint('[MatchShareHelper] Error sharing match: $e');
    }
  }

  /// Helper getter to generate preview text for tests and UI
  static String getShareText(MatchModel match) {
    final home = match.homeTeam.title;
    final away = match.awayTeam.title;
    final competition = match.championship.title;
    final scoreText = DateFormatter.toArabicNumerals('${match.homeScore ?? 0} - ${match.awayScore ?? 0}');

    if (match.isLive) {
      final minuteText = match.adminTitle != null && match.adminTitle!.isNotEmpty
          ? DateFormatter.toArabicNumerals(match.adminTitle!)
          : 'مباشر';
      return '🔴 مباشر الآن: $home $scoreText $away - الدقيقة $minuteText | $competition | عبر تطبيق شوت لايف';
    } else if (match.isFinished) {
      return '⚽ النتيجة النهائية: $home $scoreText $away | $competition | عبر تطبيق شوت لايف';
    } else {
      final matchTime = match.formattedLocalTime.isNotEmpty
          ? match.formattedLocalTime
          : (match.matchTime ?? '');
      return '⏰ مباراة $home × $away تبدأ $matchTime | $competition | عبر تطبيق شوت لايف';
    }
  }
}
