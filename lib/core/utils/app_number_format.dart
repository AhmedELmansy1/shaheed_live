/// Centralized number and numeral formatting utility.
///
/// Implements standard Latin digits (0-9, tabular figures) for all sports match
/// metrics (scores, minutes, stats, standings, poll percentages, and counts).
/// This prevents visual confusion caused by Eastern Arabic numerals (where '0'
/// appears as a dot '٠', leading to '0 - 0' looking like '· : ·').
class AppNumberFormat {
  const AppNumberFormat._();

  static const Map<String, String> _arabicToLatinMap = {
    '٠': '0',
    '١': '1',
    '٢': '2',
    '٣': '3',
    '٤': '4',
    '٥': '5',
    '٦': '6',
    '٧': '7',
    '٨': '8',
    '٩': '9',
  };

  /// Converts any Eastern Arabic digits (٠-٩) in the string to standard Latin digits (0-9).
  static String toLatinNumerals(dynamic input) {
    if (input == null) return '';
    final str = input.toString();
    var result = str;
    _arabicToLatinMap.forEach((ar, en) {
      result = result.replaceAll(ar, en);
    });
    return result;
  }

  /// Formats a single team score as Latin digits (e.g. "0", "2", "1").
  static String formatScore(dynamic score) {
    if (score == null) return '0';
    final str = toLatinNumerals(score).trim();
    if (str.isEmpty || str == '-' || str == 'null') return '0';
    return str;
  }

  /// Formats a score pair (e.g. "0 - 0", "2 - 1").
  static String formatScorePair(dynamic homeScore, dynamic awayScore) {
    final h = formatScore(homeScore);
    final a = formatScore(awayScore);
    return '$h - $a';
  }

  /// Formats a match minute marker (e.g. "45'", "90+5'", "'31").
  static String formatMinute(dynamic minute, [dynamic stoppage]) {
    final m = toLatinNumerals(minute).trim().replaceAll("'", '').replaceAll('+', '');
    final s = stoppage != null ? toLatinNumerals(stoppage).trim().replaceAll("'", '') : '';

    if (m.isEmpty) return '';
    if (s.isNotEmpty && s != '0') {
      return '$m+$s\'';
    }
    return '$m\'';
  }

  /// Formats a percentage value (e.g. "45%", "100%").
  static String formatPercentage(num pct) {
    return '${pct.round()}%';
  }

  /// Formats an integer or numeric count (e.g. "12", "1,250").
  static String formatCount(dynamic count) {
    if (count == null) return '0';
    final latin = toLatinNumerals(count).trim();
    final n = int.tryParse(latin);
    if (n == null) return latin;

    // Format thousands with comma separator
    final str = n.toString();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (Match m) => '${m[1]},');
  }

  /// Formats a clock time string (e.g. "21:00", "02:30").
  static String formatTime(String? time) {
    if (time == null || time.isEmpty) return '--:--';
    final latin = toLatinNumerals(time).trim();
    if (latin.length >= 5) {
      return latin.substring(0, 5);
    }
    return latin;
  }

  /// Formats league standings rank or points (e.g. "1", "20", "45").
  static String formatStanding(dynamic value) {
    if (value == null) return '-';
    return toLatinNumerals(value).trim();
  }

  /// Formats a match statistic (e.g. possession "65%", shots "12").
  static String formatStat(dynamic value) {
    if (value == null) return '0';
    return toLatinNumerals(value).trim();
  }
}
