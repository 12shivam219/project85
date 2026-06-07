import 'package:hive_flutter/hive_flutter.dart';

class HiveBoxes {
  static const String userProfile = 'user_profile_box';
  static const String weightHistory = 'weight_history_box';
  static const String measurementHistory = 'measurement_history_box';
  static const String dietLogs = 'diet_logs_box';
  static const String waterLogs = 'water_logs_box';
  static const String workoutLogs = 'workout_logs_box';
  static const String habitLogs = 'habit_logs_box';
  static const String progressPhotos = 'progress_photos_box';
  static const String appSettings = 'app_settings_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Open all required boxes
    await Hive.openBox(userProfile);
    await Hive.openBox(weightHistory);
    await Hive.openBox(measurementHistory);
    await Hive.openBox(dietLogs);
    await Hive.openBox(waterLogs);
    await Hive.openBox(workoutLogs);
    await Hive.openBox(habitLogs);
    await Hive.openBox(progressPhotos);
    await Hive.openBox(appSettings);
  }

  /// Helper to clear all database storage (for resetting data)
  static Future<void> clearAll() async {
    await Hive.box(userProfile).clear();
    await Hive.box(weightHistory).clear();
    await Hive.box(measurementHistory).clear();
    await Hive.box(dietLogs).clear();
    await Hive.box(waterLogs).clear();
    await Hive.box(workoutLogs).clear();
    await Hive.box(habitLogs).clear();
    await Hive.box(progressPhotos).clear();
    await Hive.box(appSettings).clear();
  }
}
