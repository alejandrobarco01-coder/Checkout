enum HabitCategory { popular, health, sports, lifestyle, time, quit }

enum HabitGoalType { build, limit, reduce, timer, counter, checklist }

class HabitTemplate {
  final String id;
  final String name;
  final String emoji;
  final HabitCategory category;
  final HabitGoalType goalType;
  final String unit;
  final int defaultTarget;
  final String description;
  final List<String> ideas;

  const HabitTemplate({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.goalType,
    required this.unit,
    required this.defaultTarget,
    required this.description,
    this.ideas = const [],
  });
}

class HabitLog {
  final String dateKey;
  final int value;
  final int elapsedSeconds;

  const HabitLog({
    required this.dateKey,
    this.value = 0,
    this.elapsedSeconds = 0,
  });

  HabitLog copyWith({
    String? dateKey,
    int? value,
    int? elapsedSeconds,
  }) {
    return HabitLog(
      dateKey: dateKey ?? this.dateKey,
      value: value ?? this.value,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }

  factory HabitLog.fromJson(Map<String, dynamic> json) {
    return HabitLog(
      dateKey: json['dateKey'] as String,
      value: json['value'] as int? ?? 0,
      elapsedSeconds: json['elapsedSeconds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'value': value,
        'elapsedSeconds': elapsedSeconds,
      };
}

class ActiveHabit {
  final String id;
  final String templateId;
  final String name;
  final String emoji;
  final HabitCategory category;
  final HabitGoalType goalType;
  final String unit;
  final int target;
  final String description;
  final int colorValue;
  final List<HabitLog> logs;
  final DateTime createdAt;

  const ActiveHabit({
    required this.id,
    required this.templateId,
    required this.name,
    required this.emoji,
    required this.category,
    required this.goalType,
    required this.unit,
    required this.target,
    required this.description,
    required this.colorValue,
    required this.logs,
    required this.createdAt,
  });

  ActiveHabit copyWith({
    String? id,
    String? templateId,
    String? name,
    String? emoji,
    HabitCategory? category,
    HabitGoalType? goalType,
    String? unit,
    int? target,
    String? description,
    int? colorValue,
    List<HabitLog>? logs,
    DateTime? createdAt,
  }) {
    return ActiveHabit(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      category: category ?? this.category,
      goalType: goalType ?? this.goalType,
      unit: unit ?? this.unit,
      target: target ?? this.target,
      description: description ?? this.description,
      colorValue: colorValue ?? this.colorValue,
      logs: logs ?? this.logs,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ActiveHabit.fromJson(Map<String, dynamic> json) {
    return ActiveHabit(
      id: json['id'] as String,
      templateId: json['templateId'] as String? ?? '',
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      category: HabitCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => HabitCategory.popular,
      ),
      goalType: HabitGoalType.values.firstWhere(
        (t) => t.name == json['goalType'],
        orElse: () => HabitGoalType.build,
      ),
      unit: json['unit'] as String? ?? 'veces',
      target: json['target'] as int? ?? 1,
      description: json['description'] as String? ?? '',
      colorValue: json['colorValue'] as int? ?? 0xFFFF5A7A,
      logs: ((json['logs'] as List?) ?? [])
          .map((e) => HabitLog.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'templateId': templateId,
        'name': name,
        'emoji': emoji,
        'category': category.name,
        'goalType': goalType.name,
        'unit': unit,
        'target': target,
        'description': description,
        'colorValue': colorValue,
        'logs': logs.map((log) => log.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };
}
