import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../domain/habit.dart';
import '../../../gamification/presentation/providers/gamification_provider.dart';
import '../../../../core/database/hive_boxes.dart';
import '../../../../core/utils/night_shift_helper.dart';

class HabitNotifier extends StateNotifier<DailyHabitsLog> {
  final Ref _ref;

  HabitNotifier(this._ref) : super(DailyHabitsLog(trackingDate: '', habits: [])) {
    final profile = _ref.read(userProfileProvider);
    final trackingDay = NightShiftHelper.getTrackingDay(DateTime.now(), startHour: profile.startHour);
    final dateStr = DateFormat('yyyy-MM-dd').format(trackingDay);
    loadDailyLog(dateStr);
  }

  void loadDailyLog(String dateStr) {
    final box = Hive.box(HiveBoxes.habitLogs);
    final logData = box.get(dateStr);

    if (logData != null) {
      final map = Map<String, dynamic>.from(logData);
      state = DailyHabitsLog.fromMap(map);
    } else {
      final newLog = DailyHabitsLog.createDefault(dateStr);
      box.put(dateStr, newLog.toMap());
      state = newLog;
    }
  }

  Future<void> toggleHabit(String habitId) async {
    bool found = false;
    bool shouldAwardXP = false;
    int xpAmount = 0;

    final updatedHabits = state.habits.map((habit) {
      if (habit.id == habitId) {
        found = true;
        final newCompleted = !habit.isCompleted;

        if (newCompleted && !habit.xpAwarded) {
          shouldAwardXP = true;
          xpAmount = (habitId == 'sleep') ? 10 : 5;
        }

        return habit.copyWith(
          isCompleted: newCompleted,
          xpAwarded: (newCompleted && !habit.xpAwarded) ? true : habit.xpAwarded,
        );
      }
      return habit;
    }).toList();

    if (!found) return;

    final updatedLog = DailyHabitsLog(
      trackingDate: state.trackingDate,
      habits: updatedHabits,
    );

    final box = Hive.box(HiveBoxes.habitLogs);
    await box.put(state.trackingDate, updatedLog.toMap());
    
    if (shouldAwardXP) {
      await _ref.read(userProfileProvider.notifier).addXp(xpAmount);
      if (habitId == 'sleep') {
        await _ref.read(userProfileProvider.notifier).incrementSleepStreak(state.trackingDate);
      }
    }

    state = updatedLog;
    await _ref.read(userProfileProvider.notifier).logDailyActivity(state.trackingDate);
  }

  /// Sync water and workout completions automatically to habits
  Future<void> syncWaterAndWorkout(bool waterDone, bool workoutDone) async {
    var modified = false;
    final updatedHabits = state.habits.map((habit) {
      if (habit.id == 'water_4l' && habit.isCompleted != waterDone) {
        modified = true;
        return habit.copyWith(isCompleted: waterDone);
      }
      if (habit.id == 'workout' && habit.isCompleted != workoutDone) {
        modified = true;
        return habit.copyWith(isCompleted: workoutDone);
      }
      return habit;
    }).toList();

    if (modified) {
      final updatedLog = DailyHabitsLog(
        trackingDate: state.trackingDate,
        habits: updatedHabits,
      );
      final box = Hive.box(HiveBoxes.habitLogs);
      await box.put(state.trackingDate, updatedLog.toMap());
      state = updatedLog;
    }
  }
}

final habitProvider = StateNotifierProvider<HabitNotifier, DailyHabitsLog>((ref) {
  return HabitNotifier(ref);
});
