
class DailyWaterLog {
  final String trackingDate; // "yyyy-MM-dd"
  final int intakeMl;
  final int goalMl;
  final bool xpAwarded;

  DailyWaterLog({
    required this.trackingDate,
    required this.intakeMl,
    this.goalMl = 4000,
    this.xpAwarded = false,
  });

  bool get isGoalAchieved => intakeMl >= goalMl;
  double get progressPercentage => (intakeMl / goalMl).clamp(0.0, 1.0);
  int get remainingMl => (goalMl - intakeMl).clamp(0, goalMl);

  DailyWaterLog copyWith({
    int? intakeMl,
    int? goalMl,
    bool? xpAwarded,
  }) {
    return DailyWaterLog(
      trackingDate: trackingDate,
      intakeMl: intakeMl ?? this.intakeMl,
      goalMl: goalMl ?? this.goalMl,
      xpAwarded: xpAwarded ?? this.xpAwarded,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trackingDate': trackingDate,
      'intakeMl': intakeMl,
      'goalMl': goalMl,
      'xpAwarded': xpAwarded,
    };
  }

  factory DailyWaterLog.fromMap(Map<String, dynamic> map) {
    return DailyWaterLog(
      trackingDate: map['trackingDate'] ?? '',
      intakeMl: map['intakeMl'] ?? 0,
      goalMl: map['goalMl'] ?? 4000,
      xpAwarded: map['xpAwarded'] ?? false,
    );
  }
}
