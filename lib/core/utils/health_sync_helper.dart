import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class HealthSyncHelper {
  static final Health _health = Health();

  static final types = [
    HealthDataType.STEPS,
    HealthDataType.WEIGHT,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.HEART_RATE,
    HealthDataType.BODY_FAT_PERCENTAGE,
  ];

  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      var status = await Permission.activityRecognition.request();
      if (status.isDenied) return false;
    }

    bool requested = await _health.requestAuthorization(types);
    return requested;
  }

  static Future<Map<String, dynamic>> fetchTodayData() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    Map<String, dynamic> data = {
      'steps': 0,
      'weight': null,
      'sleep_minutes': 0,
      'heart_rate': null,
      'body_fat': null,
    };

    try {
      List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        startTime: yesterday,
        endTime: now,
        types: types,
      );

      for (var point in healthData) {
        if (point.type == HealthDataType.STEPS) {
          final value = point.value;
          if (value is NumericHealthValue) {
             data['steps'] = (data['steps'] as int) + value.numericValue.toInt();
          }
        } else if (point.type == HealthDataType.WEIGHT) {
          final value = point.value;
          if (value is NumericHealthValue) {
            data['weight'] = value.numericValue.toDouble();
          }
        } else if (point.type == HealthDataType.BODY_FAT_PERCENTAGE) {
          final value = point.value;
          if (value is NumericHealthValue) {
            data['body_fat'] = value.numericValue.toDouble();
          }
        } else if (point.type == HealthDataType.HEART_RATE) {
          final value = point.value;
          if (value is NumericHealthValue) {
            data['heart_rate'] = value.numericValue.toDouble();
          }
        } else if (point.type == HealthDataType.SLEEP_SESSION) {
          data['sleep_minutes'] += point.dateTo.difference(point.dateFrom).inMinutes;
        }
      }
    } catch (e) {
      print("Error fetching health data: $e");
    }

    return data;
  }
}
