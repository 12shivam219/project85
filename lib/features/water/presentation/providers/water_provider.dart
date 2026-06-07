import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../domain/water_log.dart';
import '../../../gamification/presentation/providers/gamification_provider.dart';
import '../../../../core/database/hive_boxes.dart';
import '../../../../core/utils/night_shift_helper.dart';

class WaterNotifier extends StateNotifier<DailyWaterLog> {
  final Ref _ref;

  WaterNotifier(this._ref) : super(DailyWaterLog(trackingDate: '', intakeMl: 0)) {
    final profile = _ref.read(userProfileProvider);
    final trackingDay = NightShiftHelper.getTrackingDay(DateTime.now(), startHour: profile.startHour);
    final dateStr = DateFormat('yyyy-MM-dd').format(trackingDay);
    loadDailyLog(dateStr);
  }

  void loadDailyLog(String dateStr) {
    final box = Hive.box(HiveBoxes.waterLogs);
    final profile = _ref.read(userProfileProvider);
    final goalMl = (profile.dailyWaterGoalLiters * 1000).toInt();
    
    final logData = box.get(dateStr);
    if (logData != null) {
      final map = Map<String, dynamic>.from(logData);
      state = DailyWaterLog.fromMap(map);
    } else {
      final newLog = DailyWaterLog(trackingDate: dateStr, intakeMl: 0, goalMl: goalMl);
      box.put(dateStr, newLog.toMap());
      state = newLog;
    }
  }

  Future<void> logWater(int amountMl) async {
    final oldGoalAchieved = state.isGoalAchieved;
    final updatedIntake = state.intakeMl + amountMl;
    var updatedLog = state.copyWith(intakeMl: updatedIntake);

    // Check if goal was just achieved (not achieved before, achieved now)
    bool justAchieved = !oldGoalAchieved && updatedLog.isGoalAchieved;

    if (justAchieved && !state.xpAwarded) {
      updatedLog = updatedLog.copyWith(xpAwarded: true);
    }

    final box = Hive.box(HiveBoxes.waterLogs);
    await box.put(state.trackingDate, updatedLog.toMap());
    state = updatedLog;

    if (justAchieved && updatedLog.xpAwarded) {
      // Award XP (+15 XP)
      await _ref.read(userProfileProvider.notifier).addXp(15);
      await _ref.read(userProfileProvider.notifier).incrementWaterStreak(state.trackingDate);
    }
    
    await _ref.read(userProfileProvider.notifier).logDailyActivity(state.trackingDate);
  }

  Future<void> resetWater() async {
    final updatedLog = state.copyWith(intakeMl: 0);
    final box = Hive.box(HiveBoxes.waterLogs);
    await box.put(state.trackingDate, updatedLog.toMap());
    state = updatedLog;
  }
}

final waterProvider = StateNotifierProvider<WaterNotifier, DailyWaterLog>((ref) {
  return WaterNotifier(ref);
});
