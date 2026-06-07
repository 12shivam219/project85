import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/measurement.dart';
import '../../../gamification/presentation/providers/gamification_provider.dart';
import '../../../../core/database/hive_boxes.dart';

class MeasurementNotifier extends StateNotifier<List<BodyMeasurement>> {
  final Ref _ref;

  MeasurementNotifier(this._ref) : super([]) {
    _loadMeasurements();
  }

  void _loadMeasurements() {
    final box = Hive.box(HiveBoxes.measurementHistory);
    final List<BodyMeasurement> list = [];
    
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        final map = Map<String, dynamic>.from(data);
        list.add(BodyMeasurement.fromMap(map));
      }
    }
    
    // Sort by date descending
    list.sort((a, b) => b.trackingDate.compareTo(a.trackingDate));
    state = list;
  }

  Future<void> addMeasurement(BodyMeasurement entry) async {
    final box = Hive.box(HiveBoxes.measurementHistory);
    await box.put(entry.trackingDate, entry.toMap());

    // Update weight history box as well
    final weightBox = Hive.box(HiveBoxes.weightHistory);
    await weightBox.put(entry.trackingDate, entry.weightKg);

    // Refresh state list
    _loadMeasurements();

    // Check if the measurement is for the current tracking day or the latest overall,
    // and sync weight to the user profile
    if (state.isNotEmpty && state.first.trackingDate == entry.trackingDate) {
      await _ref.read(userProfileProvider.notifier).updateWeight(entry.weightKg);
      await _ref.read(userProfileProvider.notifier).logDailyActivity(entry.trackingDate);
    }
  }

  Future<void> deleteMeasurement(String trackingDate) async {
    final box = Hive.box(HiveBoxes.measurementHistory);
    await box.delete(trackingDate);

    final weightBox = Hive.box(HiveBoxes.weightHistory);
    await weightBox.delete(trackingDate);

    _loadMeasurements();

    // Sync profile weight to the next latest weight if we deleted the newest one
    if (state.isNotEmpty) {
      await _ref.read(userProfileProvider.notifier).updateWeight(state.first.weightKg);
    }
  }
}

final measurementProvider = StateNotifierProvider<MeasurementNotifier, List<BodyMeasurement>>((ref) {
  return MeasurementNotifier(ref);
});
