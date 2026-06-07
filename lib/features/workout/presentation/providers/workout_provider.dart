import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../domain/exercise.dart';
import '../../domain/workout_session.dart';
import '../../../gamification/presentation/providers/gamification_provider.dart';
import '../../../../core/database/hive_boxes.dart';
import '../../../../core/utils/night_shift_helper.dart';

class WorkoutState {
  final WorkoutSession? currentSession; // Null if no workout started today
  final List<Exercise> exerciseDb;
  final bool isLoading;

  WorkoutState({
    this.currentSession,
    required this.exerciseDb,
    this.isLoading = false,
  });

  WorkoutState copyWith({
    WorkoutSession? currentSession,
    List<Exercise>? exerciseDb,
    bool? isLoading,
    bool clearSession = false,
  }) {
    return WorkoutState(
      currentSession: clearSession ? null : (currentSession ?? this.currentSession),
      exerciseDb: exerciseDb ?? this.exerciseDb,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class WorkoutNotifier extends StateNotifier<WorkoutState> {
  final Ref _ref;

  WorkoutNotifier(this._ref) : super(WorkoutState(exerciseDb: Exercise.getInitialDatabase())) {
    final profile = _ref.read(userProfileProvider);
    final trackingDay = NightShiftHelper.getTrackingDay(DateTime.now(), startHour: profile.startHour);
    final dateStr = DateFormat('yyyy-MM-dd').format(trackingDay);
    loadDailyLog(dateStr);
  }

  void loadDailyLog(String dateStr) {
    state = state.copyWith(isLoading: true);
    final box = Hive.box(HiveBoxes.workoutLogs);
    final logData = box.get(dateStr);

    if (logData != null) {
      final map = Map<String, dynamic>.from(logData);
      state = state.copyWith(
        currentSession: WorkoutSession.fromMap(map),
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        currentSession: null,
        isLoading: false,
      );
    }
  }

  Future<void> startWorkout(String presetName) async {
    final profile = _ref.read(userProfileProvider);
    final trackingDay = NightShiftHelper.getTrackingDay(DateTime.now(), startHour: profile.startHour);
    final dateStr = DateFormat('yyyy-MM-dd').format(trackingDay);

    final newSession = WorkoutSession.createPreset(dateStr, presetName, state.exerciseDb);
    
    final box = Hive.box(HiveBoxes.workoutLogs);
    await box.put(dateStr, newSession.toMap());
    
    state = state.copyWith(currentSession: newSession);
    await _ref.read(userProfileProvider.notifier).logDailyActivity(dateStr);
  }

  Future<void> toggleSetCompletion(int exerciseIndex, int setIndex) async {
    final session = state.currentSession;
    if (session == null) return;

    final exercise = session.exercises[exerciseIndex];
    final setItem = exercise.sets[setIndex];
    final newCompleted = !setItem.isCompleted;

    final updatedSets = List<WorkoutSet>.from(exercise.sets);
    updatedSets[setIndex] = setItem.copyWith(isCompleted: newCompleted);

    final updatedExercises = List<ExerciseLog>.from(session.exercises);
    updatedExercises[exerciseIndex] = exercise.copyWith(sets: updatedSets);

    final wasCompletedBefore = session.isCompleted;
    
    // Check if session is completed overall
    bool currentlyAllCompleted = updatedExercises.every((e) => e.isCompleted);
    var updatedSession = session.copyWith(
      exercises: updatedExercises,
      isCompleted: currentlyAllCompleted,
    );
    
    bool justCompleted = false;
    if (!wasCompletedBefore && currentlyAllCompleted) {
      final nowStr = DateFormat('HH:mm').format(DateTime.now());
      updatedSession = updatedSession.copyWith(
        isCompleted: true,
        completedAtTime: nowStr,
      );
      justCompleted = true;
    } else if (wasCompletedBefore && !currentlyAllCompleted) {
      // User unchecked something, it's no longer completed
      updatedSession = updatedSession.copyWith(
        isCompleted: false,
        // We keep completedAtTime or clear it? Better clear it.
        completedAtTime: null,
      );
    }

    final box = Hive.box(HiveBoxes.workoutLogs);
    await box.put(session.trackingDate, updatedSession.toMap());
    
    state = state.copyWith(currentSession: updatedSession);

    if (justCompleted && !updatedSession.xpAwarded) {
      // Award workout XP (+25 XP)
      await _ref.read(userProfileProvider.notifier).addXp(25);
      await _ref.read(userProfileProvider.notifier).incrementWorkoutStreak(session.trackingDate);

      // Mark as awarded so they can't farm it by unchecking/checking
      final finalSession = updatedSession.copyWith(xpAwarded: true);
      await box.put(session.trackingDate, finalSession.toMap());
      state = state.copyWith(currentSession: finalSession);
    }
  }

  Future<void> updateSetWeightAndReps(int exerciseIndex, int setIndex, double weight, int reps) async {
    final session = state.currentSession;
    if (session == null) return;

    final exercise = session.exercises[exerciseIndex];
    final setItem = exercise.sets[setIndex];

    final updatedSets = List<WorkoutSet>.from(exercise.sets);
    updatedSets[setIndex] = setItem.copyWith(weightKg: weight, reps: reps);

    final updatedExercises = List<ExerciseLog>.from(session.exercises);
    updatedExercises[exerciseIndex] = exercise.copyWith(sets: updatedSets);

    final updatedSession = session.copyWith(exercises: updatedExercises);

    final box = Hive.box(HiveBoxes.workoutLogs);
    await box.put(session.trackingDate, updatedSession.toMap());
    
    state = state.copyWith(currentSession: updatedSession);
  }

  Future<void> resetWorkout() async {
    final session = state.currentSession;
    if (session == null) return;

    final box = Hive.box(HiveBoxes.workoutLogs);
    await box.delete(session.trackingDate);
    state = state.copyWith(clearSession: true);
  }
}

final workoutProvider = StateNotifierProvider<WorkoutNotifier, WorkoutState>((ref) {
  return WorkoutNotifier(ref);
});
