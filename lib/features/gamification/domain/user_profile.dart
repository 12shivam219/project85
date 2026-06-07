import 'dart:convert';

class UserProfile {
  final String name;
  final int age;
  final double heightCm;
  final double startWeight;
  final double currentWeight;
  final double targetWeight;
  final bool isMale;
  final int startHour; // Night shift mode boundary, default 17 (5 PM)
  final String wakeTime; // format: "17:00"
  final String sleepTime; // format: "04:00"
  final int xp;
  final int level;
  
  // Streaks
  final int dietStreak;
  final int workoutStreak;
  final int waterStreak;
  final int sleepStreak;
  final int overallStreak;
  final String? lastActiveDate; // Format: "yyyy-MM-dd"
  final String? lastWorkoutDate;
  final String? lastDietDate;
  final String? lastWaterDate;
  final String? lastSleepDate;

  // Goals
  final double dailyWaterGoalLiters;
  final double dailyProteinGoalGrams;
  final double dailyCaloriesGoalKcal;

  // Level Names Mapping
  static String getLevelName(int lvl) {
    if (lvl < 5) return 'Beginner';
    if (lvl < 10) return 'Recruit';
    if (lvl < 15) return 'Warrior';
    if (lvl < 20) return 'Gladiator';
    if (lvl < 25) return 'Beast';
    return 'Transformation King';
  }

  UserProfile({
    required this.name,
    required this.age,
    required this.heightCm,
    required this.startWeight,
    required this.currentWeight,
    required this.targetWeight,
    required this.isMale,
    this.startHour = 17,
    this.wakeTime = "17:00",
    this.sleepTime = "04:00",
    this.xp = 0,
    this.level = 1,
    this.dietStreak = 0,
    this.workoutStreak = 0,
    this.waterStreak = 0,
    this.sleepStreak = 0,
    this.overallStreak = 0,
    this.lastActiveDate,
    this.lastWorkoutDate,
    this.lastDietDate,
    this.lastWaterDate,
    this.lastSleepDate,
    this.dailyWaterGoalLiters = 4.0,
    this.dailyProteinGoalGrams = 170.0,
    this.dailyCaloriesGoalKcal = 2200.0,
  });

  UserProfile copyWith({
    String? name,
    int? age,
    double? heightCm,
    double? startWeight,
    double? currentWeight,
    double? targetWeight,
    bool? isMale,
    int? startHour,
    String? wakeTime,
    String? sleepTime,
    int? xp,
    int? level,
    int? dietStreak,
    int? workoutStreak,
    int? waterStreak,
    int? sleepStreak,
    int? overallStreak,
    String? lastActiveDate,
    String? lastWorkoutDate,
    String? lastDietDate,
    String? lastWaterDate,
    String? lastSleepDate,
    double? dailyWaterGoalLiters,
    double? dailyProteinGoalGrams,
    double? dailyCaloriesGoalKcal,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      startWeight: startWeight ?? this.startWeight,
      currentWeight: currentWeight ?? this.currentWeight,
      targetWeight: targetWeight ?? this.targetWeight,
      isMale: isMale ?? this.isMale,
      startHour: startHour ?? this.startHour,
      wakeTime: wakeTime ?? this.wakeTime,
      sleepTime: sleepTime ?? this.sleepTime,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      dietStreak: dietStreak ?? this.dietStreak,
      workoutStreak: workoutStreak ?? this.workoutStreak,
      waterStreak: waterStreak ?? this.waterStreak,
      sleepStreak: sleepStreak ?? this.sleepStreak,
      overallStreak: overallStreak ?? this.overallStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      lastWorkoutDate: lastWorkoutDate ?? this.lastWorkoutDate,
      lastDietDate: lastDietDate ?? this.lastDietDate,
      lastWaterDate: lastWaterDate ?? this.lastWaterDate,
      lastSleepDate: lastSleepDate ?? this.lastSleepDate,
      dailyWaterGoalLiters: dailyWaterGoalLiters ?? this.dailyWaterGoalLiters,
      dailyProteinGoalGrams: dailyProteinGoalGrams ?? this.dailyProteinGoalGrams,
      dailyCaloriesGoalKcal: dailyCaloriesGoalKcal ?? this.dailyCaloriesGoalKcal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'heightCm': heightCm,
      'startWeight': startWeight,
      'currentWeight': currentWeight,
      'targetWeight': targetWeight,
      'isMale': isMale,
      'startHour': startHour,
      'wakeTime': wakeTime,
      'sleepTime': sleepTime,
      'xp': xp,
      'level': level,
      'dietStreak': dietStreak,
      'workoutStreak': workoutStreak,
      'waterStreak': waterStreak,
      'sleepStreak': sleepStreak,
      'overallStreak': overallStreak,
      'lastActiveDate': lastActiveDate,
      'lastWorkoutDate': lastWorkoutDate,
      'lastDietDate': lastDietDate,
      'lastWaterDate': lastWaterDate,
      'lastSleepDate': lastSleepDate,
      'dailyWaterGoalLiters': dailyWaterGoalLiters,
      'dailyProteinGoalGrams': dailyProteinGoalGrams,
      'dailyCaloriesGoalKcal': dailyCaloriesGoalKcal,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'] ?? '',
      age: map['age'] ?? 0,
      heightCm: (map['heightCm'] ?? 175).toDouble(),
      startWeight: (map['startWeight'] ?? 108.0).toDouble(),
      currentWeight: (map['currentWeight'] ?? 108.0).toDouble(),
      targetWeight: (map['targetWeight'] ?? 85.0).toDouble(),
      isMale: map['isMale'] ?? true,
      startHour: map['startHour'] ?? 17,
      wakeTime: map['wakeTime'] ?? "17:00",
      sleepTime: map['sleepTime'] ?? "04:00",
      xp: map['xp'] ?? 0,
      level: map['level'] ?? 1,
      dietStreak: map['dietStreak'] ?? 0,
      workoutStreak: map['workoutStreak'] ?? 0,
      waterStreak: map['waterStreak'] ?? 0,
      sleepStreak: map['sleepStreak'] ?? 0,
      overallStreak: map['overallStreak'] ?? 0,
      lastActiveDate: map['lastActiveDate'],
      lastWorkoutDate: map['lastWorkoutDate'],
      lastDietDate: map['lastDietDate'],
      lastWaterDate: map['lastWaterDate'],
      lastSleepDate: map['lastSleepDate'],
      dailyWaterGoalLiters: (map['dailyWaterGoalLiters'] ?? 4.0).toDouble(),
      dailyProteinGoalGrams: (map['dailyProteinGoalGrams'] ?? 170.0).toDouble(),
      dailyCaloriesGoalKcal: (map['dailyCaloriesGoalKcal'] ?? 2200.0).toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory UserProfile.fromJson(String source) => UserProfile.fromMap(json.decode(source));

  static UserProfile defaultProfile() {
    return UserProfile(
      name: "Commander Shift",
      age: 32,
      heightCm: 180.0,
      startWeight: 108.0,
      currentWeight: 108.0,
      targetWeight: 85.0,
      isMale: true,
      startHour: 17,
      wakeTime: "17:00",
      sleepTime: "04:00",
      xp: 0,
      level: 1,
    );
  }
}
