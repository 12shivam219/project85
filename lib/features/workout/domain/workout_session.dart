import 'exercise.dart';

class WorkoutSet {
  final int setNumber;
  final int reps;
  final double weightKg;
  final bool isCompleted;

  WorkoutSet({
    required this.setNumber,
    required this.reps,
    required this.weightKg,
    this.isCompleted = false,
  });

  WorkoutSet copyWith({
    int? reps,
    double? weightKg,
    bool? isCompleted,
  }) {
    return WorkoutSet(
      setNumber: setNumber,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'setNumber': setNumber,
      'reps': reps,
      'weightKg': weightKg,
      'isCompleted': isCompleted,
    };
  }

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      setNumber: map['setNumber'] ?? 1,
      reps: map['reps'] ?? 10,
      weightKg: (map['weightKg'] ?? 0.0).toDouble(),
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}

class ExerciseLog {
  final String exerciseId;
  final String exerciseName;
  final List<WorkoutSet> sets;

  ExerciseLog({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
  });

  bool get isCompleted => sets.isNotEmpty && sets.every((s) => s.isCompleted);

  ExerciseLog copyWith({
    List<WorkoutSet>? sets,
  }) {
    return ExerciseLog(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      sets: sets ?? this.sets,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'sets': sets.map((s) => s.toMap()).toList(),
    };
  }

  factory ExerciseLog.fromMap(Map<String, dynamic> map) {
    return ExerciseLog(
      exerciseId: map['exerciseId'] ?? '',
      exerciseName: map['exerciseName'] ?? '',
      sets: List<WorkoutSet>.from((map['sets'] ?? []).map((x) => WorkoutSet.fromMap(x))),
    );
  }
}

class WorkoutSession {
  final String trackingDate; // "yyyy-MM-dd"
  final String name; // E.g., "Workout A (Lower)", "Workout B (Upper)", "Workout C (HIIT)"
  final List<ExerciseLog> exercises;
  final bool isCompleted;
  final bool xpAwarded;
  final String? completedAtTime; // E.g. "21:30"

  WorkoutSession({
    required this.trackingDate,
    required this.name,
    required this.exercises,
    this.isCompleted = false,
    this.xpAwarded = false,
    this.completedAtTime,
  });

  bool get checkAllCompleted => exercises.isNotEmpty && exercises.every((e) => e.isCompleted);
  double get progressPercentage {
    if (exercises.isEmpty) return 0.0;
    final totalSets = exercises.fold(0, (sum, e) => sum + e.sets.length);
    if (totalSets == 0) return 0.0;
    final completedSets = exercises.fold(0, (sum, e) => sum + e.sets.where((s) => s.isCompleted).length);
    return completedSets / totalSets;
  }

  WorkoutSession copyWith({
    List<ExerciseLog>? exercises,
    bool? isCompleted,
    bool? xpAwarded,
    String? completedAtTime,
  }) {
    return WorkoutSession(
      trackingDate: trackingDate,
      name: name,
      exercises: exercises ?? this.exercises,
      isCompleted: isCompleted ?? this.isCompleted,
      xpAwarded: xpAwarded ?? this.xpAwarded,
      completedAtTime: completedAtTime ?? this.completedAtTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trackingDate': trackingDate,
      'name': name,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'isCompleted': isCompleted,
      'xpAwarded': xpAwarded,
      'completedAtTime': completedAtTime,
    };
  }

  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    return WorkoutSession(
      trackingDate: map['trackingDate'] ?? '',
      name: map['name'] ?? '',
      exercises: List<ExerciseLog>.from((map['exercises'] ?? []).map((x) => ExerciseLog.fromMap(x))),
      isCompleted: map['isCompleted'] ?? false,
      xpAwarded: map['xpAwarded'] ?? false,
      completedAtTime: map['completedAtTime'],
    );
  }

  /// Create presets Workout A, B, and C
  static WorkoutSession createPreset(String trackingDate, String presetType, List<Exercise> db) {
    List<ExerciseLog> selectedEx = [];
    
    if (presetType == 'Workout A (Lower Body)') {
      // Goblet Squat, Romanian Deadlift, Walking Lunge, Glute Bridge
      final squat = db.firstWhere((e) => e.id == 'goblet_squat');
      final rdl = db.firstWhere((e) => e.id == 'romanian_deadlift');
      final lunge = db.firstWhere((e) => e.id == 'walking_lunge');
      final bridge = db.firstWhere((e) => e.id == 'glute_bridge');

      selectedEx = [
        ExerciseLog(exerciseId: squat.id, exerciseName: squat.name, sets: [
          WorkoutSet(setNumber: 1, reps: 12, weightKg: 16.0),
          WorkoutSet(setNumber: 2, reps: 12, weightKg: 20.0),
          WorkoutSet(setNumber: 3, reps: 10, weightKg: 24.0),
        ]),
        ExerciseLog(exerciseId: rdl.id, exerciseName: rdl.name, sets: [
          WorkoutSet(setNumber: 1, reps: 10, weightKg: 20.0),
          WorkoutSet(setNumber: 2, reps: 10, weightKg: 24.0),
          WorkoutSet(setNumber: 3, reps: 10, weightKg: 24.0),
        ]),
        ExerciseLog(exerciseId: lunge.id, exerciseName: lunge.name, sets: [
          WorkoutSet(setNumber: 1, reps: 10, weightKg: 12.0),
          WorkoutSet(setNumber: 2, reps: 10, weightKg: 12.0),
          WorkoutSet(setNumber: 3, reps: 10, weightKg: 16.0),
        ]),
        ExerciseLog(exerciseId: bridge.id, exerciseName: bridge.name, sets: [
          WorkoutSet(setNumber: 1, reps: 15, weightKg: 16.0),
          WorkoutSet(setNumber: 2, reps: 15, weightKg: 20.0),
          WorkoutSet(setNumber: 3, reps: 15, weightKg: 20.0),
        ]),
      ];
    } else if (presetType == 'Workout B (Upper Body)') {
      // Bent Over Row, Shoulder Press, Chest Fly, Band Lat Pulldown
      final row = db.firstWhere((e) => e.id == 'bent_over_row');
      final press = db.firstWhere((e) => e.id == 'shoulder_press');
      final fly = db.firstWhere((e) => e.id == 'chest_fly');
      final band = db.firstWhere((e) => e.id == 'band_lat_pulldown');

      selectedEx = [
        ExerciseLog(exerciseId: row.id, exerciseName: row.name, sets: [
          WorkoutSet(setNumber: 1, reps: 12, weightKg: 14.0),
          WorkoutSet(setNumber: 2, reps: 10, weightKg: 16.0),
          WorkoutSet(setNumber: 3, reps: 10, weightKg: 16.0),
        ]),
        ExerciseLog(exerciseId: press.id, exerciseName: press.name, sets: [
          WorkoutSet(setNumber: 1, reps: 10, weightKg: 10.0),
          WorkoutSet(setNumber: 2, reps: 10, weightKg: 12.0),
          WorkoutSet(setNumber: 3, reps: 8, weightKg: 14.0),
        ]),
        ExerciseLog(exerciseId: fly.id, exerciseName: fly.name, sets: [
          WorkoutSet(setNumber: 1, reps: 12, weightKg: 10.0),
          WorkoutSet(setNumber: 2, reps: 12, weightKg: 12.0),
          WorkoutSet(setNumber: 3, reps: 12, weightKg: 12.0),
        ]),
        ExerciseLog(exerciseId: band.id, exerciseName: band.name, sets: [
          WorkoutSet(setNumber: 1, reps: 15, weightKg: 0.0),
          WorkoutSet(setNumber: 2, reps: 15, weightKg: 0.0),
          WorkoutSet(setNumber: 3, reps: 15, weightKg: 0.0),
        ]),
      ];
    } else {
      // Workout C (Full Body / HIIT): Deadlift, HIIT Burpees, Shoulder Press, Walking Lunge
      final dl = db.firstWhere((e) => e.id == 'deadlift');
      final burpee = db.firstWhere((e) => e.id == 'hiit_burpees');
      final press = db.firstWhere((e) => e.id == 'shoulder_press');
      final lunge = db.firstWhere((e) => e.id == 'walking_lunge');

      selectedEx = [
        ExerciseLog(exerciseId: dl.id, exerciseName: dl.name, sets: [
          WorkoutSet(setNumber: 1, reps: 8, weightKg: 40.0),
          WorkoutSet(setNumber: 2, reps: 8, weightKg: 50.0),
          WorkoutSet(setNumber: 3, reps: 6, weightKg: 60.0),
        ]),
        ExerciseLog(exerciseId: burpee.id, exerciseName: burpee.name, sets: [
          WorkoutSet(setNumber: 1, reps: 10, weightKg: 0.0),
          WorkoutSet(setNumber: 2, reps: 10, weightKg: 0.0),
          WorkoutSet(setNumber: 3, reps: 10, weightKg: 0.0),
        ]),
        ExerciseLog(exerciseId: press.id, exerciseName: press.name, sets: [
          WorkoutSet(setNumber: 1, reps: 12, weightKg: 10.0),
          WorkoutSet(setNumber: 2, reps: 10, weightKg: 12.0),
          WorkoutSet(setNumber: 3, reps: 10, weightKg: 12.0),
        ]),
        ExerciseLog(exerciseId: lunge.id, exerciseName: lunge.name, sets: [
          WorkoutSet(setNumber: 1, reps: 12, weightKg: 12.0),
          WorkoutSet(setNumber: 2, reps: 12, weightKg: 12.0),
          WorkoutSet(setNumber: 3, reps: 12, weightKg: 12.0),
        ]),
      ];
    }

    return WorkoutSession(
      trackingDate: trackingDate,
      name: presetType,
      exercises: selectedEx,
    );
  }
}
