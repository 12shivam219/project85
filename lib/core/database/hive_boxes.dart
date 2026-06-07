import 'package:hive_flutter/hive_flutter.dart';
import '../utils/security_helper.dart';

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
    
    // Get secure encryption key for sensitive data
    final encryptionKey = await SecurityHelper.getEncryptionKey();
    final cipher = HiveAesCipher(encryptionKey);

    // Open boxes (Encrypted for sensitive data)
    await Hive.openBox(userProfile, encryptionCipher: cipher);
    await Hive.openBox(appSettings, encryptionCipher: cipher);

    // Standard data (Unencrypted for better performance/simplicity)
    await Hive.openBox(weightHistory);
    await Hive.openBox(measurementHistory);
    await Hive.openBox(dietLogs);
    await Hive.openBox(waterLogs);
    await Hive.openBox(workoutLogs);
    await Hive.openBox(habitLogs);
    await Hive.openBox(progressPhotos);
  }

  /// Helper to clear all database storage
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
    await SecurityHelper.deleteSecureString('openai_api_key');
  }
}
