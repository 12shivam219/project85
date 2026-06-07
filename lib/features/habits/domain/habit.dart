
class HabitItem {
  final String id;
  final String name;
  final String description;
  final bool isCompleted;
  final bool xpAwarded;

  HabitItem({
    required this.id,
    required this.name,
    required this.description,
    this.isCompleted = false,
    this.xpAwarded = false,
  });

  HabitItem copyWith({
    bool? isCompleted,
    bool? xpAwarded,
  }) {
    return HabitItem(
      id: id,
      name: name,
      description: description,
      isCompleted: isCompleted ?? this.isCompleted,
      xpAwarded: xpAwarded ?? this.xpAwarded,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isCompleted': isCompleted,
      'xpAwarded': xpAwarded,
    };
  }

  factory HabitItem.fromMap(Map<String, dynamic> map) {
    return HabitItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      xpAwarded: map['xpAwarded'] ?? false,
    );
  }
}

class DailyHabitsLog {
  final String trackingDate; // "yyyy-MM-dd"
  final List<HabitItem> habits;

  DailyHabitsLog({
    required this.trackingDate,
    required this.habits,
  });

  double get complianceRate {
    if (habits.isEmpty) return 0.0;
    final completed = habits.where((h) => h.isCompleted).length;
    return completed / habits.length;
  }

  Map<String, dynamic> toMap() {
    return {
      'trackingDate': trackingDate,
      'habits': habits.map((h) => h.toMap()).toList(),
    };
  }

  factory DailyHabitsLog.fromMap(Map<String, dynamic> map) {
    return DailyHabitsLog(
      trackingDate: map['trackingDate'] ?? '',
      habits: List<HabitItem>.from((map['habits'] ?? []).map((x) => HabitItem.fromMap(x))),
    );
  }

  static DailyHabitsLog createDefault(String trackingDate) {
    return DailyHabitsLog(
      trackingDate: trackingDate,
      habits: [
        HabitItem(id: 'sleep', name: 'Sleep 7-8 hrs', description: 'Adequate rest for night shift recovery'),
        HabitItem(id: 'water_4l', name: '4L Water Hit', description: 'Drink at least 4 liters of water'),
        HabitItem(id: 'workout', name: 'Workout Completed', description: 'Crush today\'s exercise routine'),
        HabitItem(id: 'no_junk', name: 'No Junk Food', description: 'Avoid fast foods and high calorie empty items'),
        HabitItem(id: 'no_sugar', name: 'No Sugar', description: 'No refined sugars or sweetened drinks'),
        HabitItem(id: 'protein_goal', name: 'Protein Goal Hit', description: 'Hit target protein intake'),
        HabitItem(id: 'steps_goal', name: '10k Steps', description: 'Complete 10,000 steps'),
      ],
    );
  }
}
