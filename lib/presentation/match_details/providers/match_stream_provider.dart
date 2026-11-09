import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_constants.dart';
import '../../../data/models/match_stream_model.dart';
import '../../../data/repositories/match_stream_repository.dart';

/// Provider for [MatchStreamRepository].
final matchStreamRepositoryProvider = Provider<MatchStreamRepository>((ref) {
  return FirestoreMatchStreamRepository();
});

/// Riverpod [StreamProvider.family] providing real-time stream configuration for a given match ID.
/// When [AppConstants.enableStreaming] is false (default in public store builds), yields an empty stream
/// so that the application never reads or queries stream configuration from Firestore.
final matchStreamProvider =
    StreamProvider.family<MatchStreamModel?, int>((ref, matchId) {
  if (!AppConstants.enableStreaming) {
    return Stream.value(null);
  }
  final repo = ref.watch(matchStreamRepositoryProvider);
  return repo.listenToMatchStream(matchId);
});
