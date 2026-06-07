import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/user_profile.dart';
import '../../domain/achievement.dart';
import '../../../workout/domain/workout_session.dart';
import '../../../../core/database/hive_boxes.dart';
import '../../../../core/utils/notification_helper.dart';

class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier() : super(UserProfile.defaultProfile()) {
    _loadProfile();
  }

  void _loadProfile() {
    final box = Hive.box(HiveBoxes.userProfile);
    final profileData = box.get('current_profile');
    if (profileData != null) {
      // Data is stored as a Map<dynamic, dynamic> in Hive. Convert to Map<String, dynamic>.
      final map = Map<String, dynamic>.from(profileData);
      state = UserProfile.fromMap(map);
    } else {
      // If no profile exists, save default
      state = UserProfile.defaultProfile();
      _saveProfile();
    }

    // Schedule reminders on load
    NotificationHelper.scheduleShiftReminders(state);
  }

  Future<void> _saveProfile() async {
    final box = Hive.box(HiveBoxes.userProfile);
    await box.put('current_profile', state.toMap());

    // Refresh reminders whenever profile changes
    await NotificationHelper.scheduleShiftReminders(state);
  }

  /// Adds XP, checks for level up
  Future<bool> addXp(int amount) async {
    int currentXp = state.xp + amount;
    int currentLevel = state.level;
    bool leveledUp = false;

    // Progression curve: Level 1 needs 100XP, Level 2 needs 150XP, Level 3 needs 200XP, etc.
    // xpRequired = 100 + (level - 1) * 50
    int xpNeededForNextLevel = 100 + (currentLevel - 1) * 50;
    while (currentXp >= xpNeededForNextLevel && currentLevel < 30) {
      currentXp -= xpNeededForNextLevel;
      currentLevel++;
      leveledUp = true;
      xpNeededForNextLevel = 100 + (currentLevel - 1) * 50;
    }

    state = state.copyWith(
      xp: currentXp,
      level: currentLevel,
    );
    await _saveProfile();
    
    if (leveledUp) {
      // Check/evaluate badges immediately when level/XP changes
      await evaluateAllBadges();
    }
    return leveledUp;
  }

  /// Updates current weight and estimates Body Fat & BMR
  Future<void> updateWeight(double weightKg) async {
    state = state.copyWith(currentWeight: weightKg);
    await _saveProfile();
    await evaluateAllBadges();
  }

  /// Update general profile settings
  Future<void> updateProfile({
    required String name,
    required int age,
    required double heightCm,
    required double targetWeight,
    required bool isMale,
    required int startHour,
    required String wakeTime,
    required String sleepTime,
    required double dailyWaterGoal,
    required double dailyProteinGoal,
    required double dailyCaloriesGoal,
  }) async {
    state = state.copyWith(
      name: name,
      age: age,
      heightCm: heightCm,
      targetWeight: targetWeight,
      isMale: isMale,
      startHour: startHour,
      wakeTime: wakeTime,
      sleepTime: sleepTime,
      dailyWaterGoalLiters: dailyWaterGoal,
      dailyProteinGoalGrams: dailyProteinGoal,
      dailyCaloriesGoalKcal: dailyCaloriesGoal,
    );
    await _saveProfile();
    await evaluateAllBadges();
  }

  /// Update active date and recalculate streaks
  Future<void> logDailyActivity(String trackingDateStr) async {
    final lastActive = state.lastActiveDate;
    if (lastActive == null) {
      // First activity log
      state = state.copyWith(
        lastActiveDate: trackingDateStr,
        overallStreak: 1,
      );
    } else if (lastActive != trackingDateStr) {
      final lastActiveDate = DateTime.parse(lastActive);
      final currentDate = DateTime.parse(trackingDateStr);
      final difference = currentDate.difference(lastActiveDate).inDays;

      if (difference == 1) {
        // Consecutive tracking day
        state = state.copyWith(
          lastActiveDate: trackingDateStr,
          overallStreak: state.overallStreak + 1,
        );
      } else if (difference > 1) {
        // Streak broken
        state = state.copyWith(
          lastActiveDate: trackingDateStr,
          overallStreak: 1,
        );
      }
    }
    await _saveProfile();
    await evaluateAllBadges();
  }

  /// Increments streak for specific activities
  Future<void> incrementDietStreak(String date) async {
    if (state.lastDietDate != date) {
      state = state.copyWith(
        dietStreak: state.dietStreak + 1,
        lastDietDate: date,
      );
      await _saveProfile();
    }
  }
  
  Future<void> incrementWorkoutStreak(String date) async {
    if (state.lastWorkoutDate != date) {
      state = state.copyWith(
        workoutStreak: state.workoutStreak + 1,
        lastWorkoutDate: date,
      );
      await _saveProfile();
    }
  }

  Future<void> incrementWaterStreak(String date) async {
    if (state.lastWaterDate != date) {
      state = state.copyWith(
        waterStreak: state.waterStreak + 1,
        lastWaterDate: date,
      );
      await _saveProfile();
    }
  }

  Future<void> incrementSleepStreak(String date) async {
    if (state.lastSleepDate != date) {
      state = state.copyWith(
        sleepStreak: state.sleepStreak + 1,
        lastSleepDate: date,
      );
      await _saveProfile();
    }
  }

  /// Resets streak for specific activities
  Future<void> resetStreaks({bool diet = false, bool workout = false, bool water = false, bool sleep = false}) async {
    state = state.copyWith(
      dietStreak: diet ? 0 : state.dietStreak,
      workoutStreak: workout ? 0 : state.workoutStreak,
      waterStreak: water ? 0 : state.waterStreak,
      sleepStreak: sleep ? 0 : state.sleepStreak,
    );
    await _saveProfile();
  }

  /// Evaluates and unlocks badges
  Future<List<BadgeModel>> evaluateAllBadges() async {
    final badgesBox = Hive.box(HiveBoxes.userProfile);
    
    // Load existing badges or create defaults
    List<BadgeModel> currentBadges = [];
    final savedBadges = badgesBox.get('unlocked_badges');
    if (savedBadges != null) {
      currentBadges = List<BadgeModel>.from(
        (savedBadges as List).map((x) => BadgeModel.fromMap(Map<String, dynamic>.from(x)))
      );
    } else {
      currentBadges = BadgeModel.getInitialBadges();
    }

    // Load completed workouts count to check first workout badge
    final workoutBox = Hive.box(HiveBoxes.workoutLogs);
    int totalWorkouts = 0;
    for (var key in workoutBox.keys) {
      final logData = workoutBox.get(key);
      if (logData != null) {
        final session = WorkoutSession.fromMap(Map<String, dynamic>.from(logData));
        if (session.isCompleted) {
          totalWorkouts++;
        }
      }
    }

    final updatedBadges = BadgeModel.evaluateBadges(state, currentBadges, totalWorkouts);
    
    // Save updated badges list
    await badgesBox.put('unlocked_badges', updatedBadges.map((b) => b.toMap()).toList());
    
    return updatedBadges;
  }
}

// Global Provider for User Profile
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier();
});

// Badges Provider
final badgesProvider = FutureProvider<List<BadgeModel>>((ref) async {
  final profileNotifier = ref.read(userProfileProvider.notifier);
  return await profileNotifier.evaluateAllBadges();
});
