import 'date_formatter.dart';
import '../../data/models/match_stream_model.dart';

enum StreamAvailabilityState {
  /// Active stream configuration exists on Firestore (is_enabled == true && hasActiveServers)
  streamAvailable,

  /// More than 5 minutes before match kickoff date/time AND no active stream
  preMatchWaiting,

  /// Within 5 minutes before match kickoff date/time (0 <= kickoff - now <= 5 mins) AND no active stream
  preparingStream,

  /// Match has started or finished (now >= kickoff or isLive/isFinished) AND no active stream
  matchStartedNoStream,
}

class StreamAvailabilityResult {
  final StreamAvailabilityState state;
  final Duration? remainingTime;

  const StreamAvailabilityResult({
    required this.state,
    this.remainingTime,
  });
}

class StreamAvailabilityHelper {
  /// Evaluates current stream availability state.
  static StreamAvailabilityResult evaluate({
    required MatchStreamModel? streamModel,
    required DateTime? kickoffDateTime,
    required DateTime now,
    bool isLive = false,
    bool isFinished = false,
  }) {
    // STATE D — STREAM AVAILABLE
    if (streamModel != null && streamModel.isEnabled && streamModel.hasActiveServers) {
      return const StreamAvailabilityResult(
        state: StreamAvailabilityState.streamAvailable,
      );
    }

    // If match is live or finished or current time is past kickoff, state is C (match started, no stream yet)
    if (isLive || isFinished) {
      return const StreamAvailabilityResult(
        state: StreamAvailabilityState.matchStartedNoStream,
      );
    }

    if (kickoffDateTime == null) {
      return const StreamAvailabilityResult(
        state: StreamAvailabilityState.matchStartedNoStream,
      );
    }

    final diff = kickoffDateTime.difference(now);

    if (diff.isNegative) {
      // Current time is past scheduled kickoff date/time
      return const StreamAvailabilityResult(
        state: StreamAvailabilityState.matchStartedNoStream,
      );
    }

    if (diff > const Duration(minutes: 5)) {
      // STATE A — MORE THAN 5 MINUTES BEFORE KICKOFF
      return StreamAvailabilityResult(
        state: StreamAvailabilityState.preMatchWaiting,
        remainingTime: diff,
      );
    } else {
      // STATE B — WITHIN 5 MINUTES BEFORE KICKOFF
      return StreamAvailabilityResult(
        state: StreamAvailabilityState.preparingStream,
        remainingTime: diff,
      );
    }
  }

  /// Formats duration into natural Arabic string (e.g., "ساعة و ٢٤ دقيقة", "٤٥ دقيقة", "غداً").
  static String formatNaturalArabicCountdown(Duration diff) {
    if (diff.isNegative) return 'لحظات';

    final inDays = diff.inDays;
    final inHours = diff.inHours;
    final inMinutes = diff.inMinutes;

    if (inDays >= 2) {
      return DateFormatter.toArabicNumerals('$inDays أيام');
    } else if (inDays == 1) {
      return 'غداً';
    }

    if (inHours >= 1) {
      final remainingMins = inMinutes % 60;
      final hoursStr = DateFormatter.toArabicNumerals(inHours.toString());
      if (remainingMins == 0) {
        return inHours == 1 ? 'ساعة واحدة' : '$hoursStr ساعات';
      }
      final minsStr = DateFormatter.toArabicNumerals(remainingMins.toString());
      if (inHours == 1) {
        return 'ساعة و $minsStr دقيقة';
      }
      return '$hoursStr ساعة و $minsStr دقيقة';
    } else {
      final mins = inMinutes <= 0 ? 1 : inMinutes;
      final minsStr = DateFormatter.toArabicNumerals(mins.toString());
      return '$minsStr دقيقة';
    }
  }

  /// Formats duration into natural English string (e.g., "1 hour 24 minutes", "45 minutes", "Tomorrow").
  static String formatNaturalEnglishCountdown(Duration diff) {
    if (diff.isNegative) return 'moments';

    final inDays = diff.inDays;
    final inHours = diff.inHours;
    final inMinutes = diff.inMinutes;

    if (inDays >= 2) {
      return '$inDays days';
    } else if (inDays == 1) {
      return 'Tomorrow';
    }

    if (inHours >= 1) {
      final remainingMins = inMinutes % 60;
      if (remainingMins == 0) {
        return '$inHours ${inHours == 1 ? 'hour' : 'hours'}';
      }
      return '$inHours ${inHours == 1 ? 'hour' : 'hours'} $remainingMins ${remainingMins == 1 ? 'minute' : 'minutes'}';
    } else {
      final mins = inMinutes <= 0 ? 1 : inMinutes;
      return '$mins ${mins == 1 ? 'minute' : 'minutes'}';
    }
  }
}
