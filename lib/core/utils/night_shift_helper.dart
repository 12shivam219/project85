import 'package:intl/intl.dart';

class NightShiftHelper {
  /// Resolves the actual virtual "Tracking Date" (truncated to midnight)
  /// given a local date/time and the shift start hour.
  /// 
  /// E.g. If startHour = 17 (5 PM):
  /// - 2026-06-07 16:30 -> Returns 2026-06-06 (still part of yesterday's shift)
  /// - 2026-06-07 17:15 -> Returns 2026-06-07 (start of today's shift)
  static DateTime getTrackingDay(DateTime localTime, {int startHour = 17}) {
    if (localTime.hour < startHour) {
      final previousDay = localTime.subtract(const Duration(days: 1));
      return DateTime(previousDay.year, previousDay.month, previousDay.day);
    } else {
      return DateTime(localTime.year, localTime.month, localTime.day);
    }
  }

  /// Check if two real DateTimes fall into the same tracking shift day
  static bool isSameTrackingDay(DateTime time1, DateTime time2, {int startHour = 17}) {
    final track1 = getTrackingDay(time1, startHour: startHour);
    final track2 = getTrackingDay(time2, startHour: startHour);
    return track1.year == track2.year &&
           track1.month == track2.month &&
           track1.day == track2.day;
  }

  /// Gets the real local start time of a specific tracking day.
  /// E.g., for tracking day 2026-06-07 and startHour = 17, returns 2026-06-07 17:00:00.000
  static DateTime getStartOfTrackingDay(DateTime trackingDay, {int startHour = 17}) {
    return DateTime(trackingDay.year, trackingDay.month, trackingDay.day, startHour);
  }

  /// Gets the real local end time of a specific tracking day.
  /// E.g., for tracking day 2026-06-07 and startHour = 17, returns 2026-06-08 16:59:59.999
  static DateTime getEndOfTrackingDay(DateTime trackingDay, {int startHour = 17}) {
    final nextDay = trackingDay.add(const Duration(days: 1));
    return DateTime(nextDay.year, nextDay.month, nextDay.day, startHour)
        .subtract(const Duration(milliseconds: 1));
  }

  /// Helper to format the tracking date in a readable form
  static String formatTrackingDay(DateTime trackingDay) {
    return DateFormat('EEEE, MMM d').format(trackingDay);
  }

  /// Helper to calculate target completion date based on standard weight loss rate.
  /// Standard healthy weight loss is about 0.5kg to 1.0kg per week.
  /// We'll use 0.7kg/week as pace.
  static DateTime calculateTargetDate(double currentWeight, double targetWeight, DateTime startDate) {
    if (currentWeight <= targetWeight) return startDate;
    final double weightToLose = currentWeight - targetWeight;
    final double weeksNeeded = weightToLose / 0.7; // 0.7 kg per week
    final int daysNeeded = (weeksNeeded * 7).round();
    return startDate.add(Duration(days: daysNeeded));
  }
}
