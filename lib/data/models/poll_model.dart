import '../../core/utils/app_number_format.dart';

/// Single option inside a match poll.
class PollOption {
  final String id;
  final String label;
  final int votes;

  const PollOption({
    required this.id,
    required this.label,
    this.votes = 0,
  });

  factory PollOption.fromMap(Map<String, dynamic> map) {
    int parseVotes(dynamic val) {
      if (val is num) return val.toInt();
      return int.tryParse(val?.toString() ?? '') ?? 0;
    }

    return PollOption(
      id: map['id']?.toString() ?? 'opt_0',
      label: map['label']?.toString() ?? '',
      votes: parseVotes(map['votes']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'votes': votes,
  };

  PollOption copyWith({int? votes}) => PollOption(
    id: id,
    label: label,
    votes: votes ?? this.votes,
  );
}

/// Data model representing a Match Poll from `match_polls/{matchId}`.
class PollModel {
  final String matchId;
  final String question;
  final List<PollOption> options;
  final int totalVotes;
  final bool enabled;
  final String? userVotedOptionId;

  const PollModel({
    required this.matchId,
    required this.question,
    required this.options,
    this.totalVotes = 0,
    this.enabled = true,
    this.userVotedOptionId,
  });

  bool get hasUserVoted => userVotedOptionId != null && userVotedOptionId!.isNotEmpty;

  int percentageOf(PollOption option) {
    if (totalVotes <= 0) return 0;
    return ((option.votes / totalVotes) * 100).round();
  }

  String formattedPercentageOf(PollOption option) {
    final pct = percentageOf(option);
    return AppNumberFormat.formatPercentage(pct);
  }

  factory PollModel.fromMap(Map<String, dynamic> map, String docId, {String? userVotedOptionId}) {
    int parseTotal(dynamic val) {
      if (val is num) return val.toInt();
      return int.tryParse(val?.toString() ?? '') ?? 0;
    }

    final rawOptions = map['options'];
    final optionsList = <PollOption>[];
    if (rawOptions is List) {
      for (final item in rawOptions) {
        if (item is Map) {
          optionsList.add(PollOption.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    } else if (rawOptions is Map) {
      for (final item in rawOptions.values) {
        if (item is Map) {
          optionsList.add(PollOption.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    return PollModel(
      matchId: (map['match_id']?.toString()) ?? docId,
      question: (map['question']?.toString()) ?? 'من تتوقع أن يفوز بمباراة اليوم؟',
      options: optionsList,
      totalVotes: parseTotal(map['total_votes']),
      enabled: map['enabled'] == true || map['enabled'] == null || map['enabled'] == 1,
      userVotedOptionId: userVotedOptionId,
    );
  }

  PollModel copyWith({
    List<PollOption>? options,
    int? totalVotes,
    String? userVotedOptionId,
  }) {
    return PollModel(
      matchId: matchId,
      question: question,
      options: options ?? this.options,
      totalVotes: totalVotes ?? this.totalVotes,
      enabled: enabled,
      userVotedOptionId: userVotedOptionId ?? this.userVotedOptionId,
    );
  }
}

