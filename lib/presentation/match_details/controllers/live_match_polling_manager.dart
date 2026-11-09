import 'dart:async';
import 'package:flutter/widgets.dart';

/// Manages the 30-second live polling loop for active matches.
///
/// Lifecycle Guarantees:
/// 1. Runs ONLY while the match details screen is visible AND the match is live.
/// 2. Pauses automatically when the app is backgrounded via [WidgetsBindingObserver].
/// 3. Resumes immediately upon foregrounding if the match is still live.
/// 4. Cancels cleanly and completely on screen disposal.
/// 5. Prevents overlapping async requests while a poll is in flight.
/// 6. Applies a small exponential backoff on consecutive network/server errors.
class LiveMatchPollingManager with WidgetsBindingObserver {
  final Future<void> Function() onPoll;
  final bool isLive;
  final Duration baseInterval;
  final Duration errorBackoffInterval;

  Timer? _timer;
  bool _isDisposed = false;
  bool _isPaused = false;
  bool _isFetching = false;
  int _consecutiveErrors = 0;

  LiveMatchPollingManager({
    required this.onPoll,
    required this.isLive,
    this.baseInterval = const Duration(seconds: 30),
    this.errorBackoffInterval = const Duration(seconds: 10),
  });

  /// Starts the polling lifecycle if the match is currently live.
  void start() {
    if (!isLive || _isDisposed) return;
    WidgetsBinding.instance.addObserver(this);
    _scheduleNext(baseInterval);
  }

  void _scheduleNext(Duration delay) {
    _timer?.cancel();
    if (_isDisposed || _isPaused || !isLive) return;
    _timer = Timer(delay, () => executePoll());
  }

  /// Executes a single polling iteration with guard against overlaps and backoff on error.
  Future<void> executePoll() async {
    if (_isDisposed || _isPaused || _isFetching || !isLive) return;
    _isFetching = true;

    try {
      await onPoll();
      _consecutiveErrors = 0;
      if (!_isDisposed && !_isPaused) {
        _scheduleNext(baseInterval);
      }
    } catch (_) {
      _consecutiveErrors++;
      // Backoff: 10s on first error, capped at 30s
      final backoffSeconds = (errorBackoffInterval.inSeconds * _consecutiveErrors).clamp(10, 30);
      if (!_isDisposed && !_isPaused) {
        _scheduleNext(Duration(seconds: backoffSeconds));
      }
    } finally {
      _isFetching = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      resume();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      pause();
    }
  }

  /// Pauses polling when the app goes into the background.
  void pause() {
    _isPaused = true;
    _timer?.cancel();
    _timer = null;
  }

  /// Resumes polling when the app returns to the foreground.
  void resume() {
    if (!_isPaused || _isDisposed || !isLive) return;
    _isPaused = false;
    executePoll();
  }

  /// Cancels all timers and removes observers on screen disposal.
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  // Observable state for testing & diagnostics
  bool get isActive => _timer != null && _timer!.isActive;
  bool get isPaused => _isPaused;
  bool get isFetching => _isFetching;
  bool get isDisposed => _isDisposed;
  int get consecutiveErrors => _consecutiveErrors;
}

