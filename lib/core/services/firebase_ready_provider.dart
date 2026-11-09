import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../firebase_options.dart';

enum FirebaseInitStatus {
  uninitialized,
  initializing,
  ready,
  failed,
}

@immutable
class FirebaseReadyState {
  final FirebaseInitStatus status;
  final int initDurationMs;
  final String? error;

  const FirebaseReadyState({
    required this.status,
    required this.initDurationMs,
    this.error,
  });

  bool get isReady => status == FirebaseInitStatus.ready;

  static const uninitialized = FirebaseReadyState(
    status: FirebaseInitStatus.uninitialized,
    initDurationMs: 0,
  );

  FirebaseReadyState copyWith({
    FirebaseInitStatus? status,
    int? initDurationMs,
    String? error,
  }) {
    return FirebaseReadyState(
      status: status ?? this.status,
      initDurationMs: initDurationMs ?? this.initDurationMs,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'FirebaseReadyState(status: $status, duration: ${initDurationMs}ms, error: $error)';
  }
}

class FirebaseReadyNotifier extends Notifier<FirebaseReadyState> {
  final Completer<bool> _readyCompleter = Completer<bool>();
  Future<void>? _initOperation;

  @override
  FirebaseReadyState build() {
    return FirebaseReadyState.uninitialized;
  }

  Future<bool> get isReadyFuture => _readyCompleter.future;

  /// Awaits readiness up to [timeout]. Returns true if ready, false on failure or timeout.
  Future<bool> awaitReady({Duration timeout = const Duration(seconds: 10)}) async {
    if (state.isReady) return true;
    if (state.status == FirebaseInitStatus.failed) return false;

    try {
      return await _readyCompleter.future.timeout(timeout, onTimeout: () => false);
    } catch (_) {
      return false;
    }
  }

  /// Initiates Firebase initialization safely. Idempotent across multiple calls.
  Future<void> initializeFirebase({BackgroundMessageHandler? backgroundMessageHandler}) async {
    if (_initOperation != null) return _initOperation!;

    final completer = Completer<void>();
    _initOperation = completer.future;

    state = state.copyWith(status: FirebaseInitStatus.initializing);
    final stopwatch = Stopwatch()..start();

    try {
      // 1. Initialize Firebase Core
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (_) {
        await Firebase.initializeApp();
      }

      // 2. Register background messaging handler if supplied
      if (backgroundMessageHandler != null) {
        FirebaseMessaging.onBackgroundMessage(backgroundMessageHandler);
      }

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;

      state = FirebaseReadyState(
        status: FirebaseInitStatus.ready,
        initDurationMs: duration,
      );

      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete(true);
      }
      debugPrint('[FirebaseReady] Firebase initialized successfully in ${duration}ms.');
    } catch (e, stack) {
      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;
      debugPrint('[FirebaseReady] Firebase init error after ${duration}ms: $e\n$stack');

      state = FirebaseReadyState(
        status: FirebaseInitStatus.failed,
        initDurationMs: duration,
        error: e.toString(),
      );

      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete(false);
      }
    } finally {
      completer.complete();
    }
  }

  /// Allows unit tests or mock setups to mark Firebase as ready directly.
  @visibleForTesting
  void markReadyManually({int durationMs = 0}) {
    state = FirebaseReadyState(
      status: FirebaseInitStatus.ready,
      initDurationMs: durationMs,
    );
    if (!_readyCompleter.isCompleted) {
      _readyCompleter.complete(true);
    }
  }

  /// Allows unit tests or mock setups to mark Firebase as failed directly.
  @visibleForTesting
  void markFailedManually(Object error, {int durationMs = 0}) {
    state = FirebaseReadyState(
      status: FirebaseInitStatus.failed,
      initDurationMs: durationMs,
      error: error.toString(),
    );
    if (!_readyCompleter.isCompleted) {
      _readyCompleter.complete(false);
    }
  }
}

final firebaseReadyProvider =
    NotifierProvider<FirebaseReadyNotifier, FirebaseReadyState>(
  FirebaseReadyNotifier.new,
);
