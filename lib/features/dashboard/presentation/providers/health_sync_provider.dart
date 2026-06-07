import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../gamification/presentation/providers/gamification_provider.dart';
import '../../../measurements/presentation/providers/measurement_provider.dart';
import '../../../measurements/domain/measurement.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../../core/utils/health_sync_helper.dart';
import '../../../../core/utils/night_shift_helper.dart';

class HealthSyncState {
  final bool isSyncing;
  final String? lastSyncTime;
  final String? error;

  HealthSyncState({this.isSyncing = false, this.lastSyncTime, this.error});

  HealthSyncState copyWith({bool? isSyncing, String? lastSyncTime, String? error}) {
    return HealthSyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      error: error ?? this.error,
    );
  }
}

class HealthSyncNotifier extends StateNotifier<HealthSyncState> {
  final Ref _ref;

  HealthSyncNotifier(this._ref) : super(HealthSyncState());

  Future<void> syncData() async {
    state = state.copyWith(isSyncing: true, error: null);

    try {
      bool permitted = await HealthSyncHelper.requestPermissions();
      if (!permitted) {
        state = state.copyWith(isSyncing: false, error: "Permissions denied.");
        return;
      }

      final data = await HealthSyncHelper.fetchTodayData();
      final profile = _ref.read(userProfileProvider);
      final trackingDay = NightShiftHelper.getTrackingDay(DateTime.now(), startHour: profile.startHour);
      final dateStr = DateFormat('yyyy-MM-dd').format(trackingDay);

      if (data['weight'] != null) {
        final weight = data['weight'] as double;
        final bf = (data['body_fat'] as double?) ?? 0.0;
        final entry = BodyMeasurement(
          trackingDate: dateStr,
          weightKg: weight,
          bodyFatPercentage: bf,
        );
        await _ref.read(measurementProvider.notifier).addMeasurement(entry);
      }

      if (data['steps'] > 0) {
        final steps = data['steps'] as int;
        if (steps >= 10000) {
          final habits = _ref.read(habitProvider).habits;
          final stepsHabit = habits.firstWhere((h) => h.id == 'steps_goal');
          if (!stepsHabit.isCompleted) {
            await _ref.read(habitProvider.notifier).toggleHabit('steps_goal');
          }
        }
      }

      if (data['sleep_minutes'] > 0) {
        final sleepMinutes = data['sleep_minutes'] as int;
        if (sleepMinutes >= 420) {
          final habits = _ref.read(habitProvider).habits;
          final sleepHabit = habits.firstWhere((h) => h.id == 'sleep');
          if (!sleepHabit.isCompleted) {
            await _ref.read(habitProvider.notifier).toggleHabit('sleep');
          }
        }
      }

      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: DateFormat('HH:mm').format(DateTime.now()),
      );
    } catch (e) {
      state = state.copyWith(isSyncing: false, error: "Sync failed");
    }
  }
}

final healthSyncProvider = StateNotifierProvider<HealthSyncNotifier, HealthSyncState>((ref) {
  return HealthSyncNotifier(ref);
});
