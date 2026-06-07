import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../domain/meal.dart';
import '../../../gamification/presentation/providers/gamification_provider.dart';
import '../../../../core/database/hive_boxes.dart';
import '../../../../core/utils/night_shift_helper.dart';

class DietLogState {
  final DailyDietLog currentLog;
  final bool isLoading;

  DietLogState({required this.currentLog, this.isLoading = false});

  DietLogState copyWith({DailyDietLog? currentLog, bool? isLoading}) {
    return DietLogState(
      currentLog: currentLog ?? this.currentLog,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class DietNotifier extends StateNotifier<DietLogState> {
  final Ref _ref;
  
  DietNotifier(this._ref) : super(DietLogState(currentLog: DailyDietLog(trackingDate: '', meals: []))) {
    // Load for current tracking day
    final profile = _ref.read(userProfileProvider);
    final trackingDay = NightShiftHelper.getTrackingDay(DateTime.now(), startHour: profile.startHour);
    final dateStr = DateFormat('yyyy-MM-dd').format(trackingDay);
    loadDailyLog(dateStr);
  }

  Future<void> loadDailyLog(String dateStr) async {
    state = state.copyWith(isLoading: true);
    final box = Hive.box(HiveBoxes.dietLogs);
    final logData = box.get(dateStr);

    if (logData != null) {
      final map = Map<String, dynamic>.from(logData);
      state = DietLogState(currentLog: DailyDietLog.fromMap(map), isLoading: false);
    } else {
      // Create new default diet log for this day
      final newLog = DailyDietLog.createDefault(dateStr);
      await box.put(dateStr, newLog.toMap());
      state = DietLogState(currentLog: newLog, isLoading: false);
    }
  }

  Future<void> toggleMealCompletion(String mealId, bool completed) async {
    bool shouldAwardXP = false;
    final updatedMeals = state.currentLog.meals.map((meal) {
      if (meal.id == mealId) {
        final nowStr = DateFormat('HH:mm').format(DateTime.now());

        // Only award XP if it's being completed and hasn't been awarded before for this meal
        if (completed && !meal.xpAwarded) {
          shouldAwardXP = true;
        }

        return meal.copyWith(
          isCompleted: completed,
          completionTime: completed ? nowStr : null,
          xpAwarded: (completed && !meal.xpAwarded) ? true : meal.xpAwarded,
        );
      }
      return meal;
    }).toList();

    final updatedLog = DailyDietLog(
      trackingDate: state.currentLog.trackingDate,
      meals: updatedMeals,
    );

    // Save to Hive
    final box = Hive.box(HiveBoxes.dietLogs);
    await box.put(state.currentLog.trackingDate, updatedLog.toMap());
    state = state.copyWith(currentLog: updatedLog);

    // Award XP on completion (+10 XP)
    if (shouldAwardXP) {
      await _ref.read(userProfileProvider.notifier).addXp(10);
      await _ref.read(userProfileProvider.notifier).logDailyActivity(state.currentLog.trackingDate);
    }

    // Increment diet streak if not already handled today (logDailyActivity handles overall streak)
    // Note: In a full implementation, we might want to only increment dietStreak once all meals are done.
    // For now, we'll follow the original logic which increments it when any meal is completed.
    if (shouldAwardXP) {
       // We only increment diet streak once per day if possible.
       await _ref.read(userProfileProvider.notifier).incrementDietStreak(state.currentLog.trackingDate);
    }
  }

  Future<void> updateMealNotes(String mealId, String notes) async {
    final updatedMeals = state.currentLog.meals.map((meal) {
      if (meal.id == mealId) {
        return meal.copyWith(notes: notes);
      }
      return meal;
    }).toList();

    final updatedLog = DailyDietLog(
      trackingDate: state.currentLog.trackingDate,
      meals: updatedMeals,
    );

    final box = Hive.box(HiveBoxes.dietLogs);
    await box.put(state.currentLog.trackingDate, updatedLog.toMap());
    state = state.copyWith(currentLog: updatedLog);
  }

  Future<void> updateMealMacros(String mealId, double calories, double protein, double carbs, double fat) async {
    final updatedMeals = state.currentLog.meals.map((meal) {
      if (meal.id == mealId) {
        return meal.copyWith(
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
        );
      }
      return meal;
    }).toList();

    final updatedLog = DailyDietLog(
      trackingDate: state.currentLog.trackingDate,
      meals: updatedMeals,
    );

    final box = Hive.box(HiveBoxes.dietLogs);
    await box.put(state.currentLog.trackingDate, updatedLog.toMap());
    state = state.copyWith(currentLog: updatedLog);
  }
}

// Global Provider for Diet Notifier
final dietProvider = StateNotifierProvider<DietNotifier, DietLogState>((ref) {
  return DietNotifier(ref);
});
