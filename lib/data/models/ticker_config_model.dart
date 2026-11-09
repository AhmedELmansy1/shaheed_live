import 'dart:convert';

/// Data model representing the breaking news ticker configuration (`config/app_settings.ticker_config`).
class TickerConfigModel {
  final bool enabled;
  final String text;
  final String type; // 'breaking', 'info', 'warning'
  final String? actionUrl;

  const TickerConfigModel({
    this.enabled = false,
    this.text = '',
    this.type = 'breaking',
    this.actionUrl,
  });

  factory TickerConfigModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const TickerConfigModel();
    return TickerConfigModel(
      enabled: map['enabled'] as bool? ?? false,
      text: (map['text'] as String?)?.trim() ?? '',
      type: (map['type'] as String?)?.trim() ?? 'breaking',
      actionUrl: (map['action_url'] as String?)?.trim(),
    );
  }

  factory TickerConfigModel.fromJson(String source) {
    try {
      final map = jsonDecode(source) as Map<String, dynamic>;
      return TickerConfigModel.fromMap(map);
    } catch (_) {
      return const TickerConfigModel();
    }
  }

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'text': text,
    'type': type,
    'action_url': actionUrl,
  };

  String toJson() => jsonEncode(toMap());

  bool get isValid => enabled && text.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TickerConfigModel &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          text == other.text &&
          type == other.type &&
          actionUrl == other.actionUrl;

  @override
  int get hashCode =>
      enabled.hashCode ^ text.hashCode ^ type.hashCode ^ actionUrl.hashCode;
}

