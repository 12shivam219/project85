import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import 'package:project85/core/database/hive_boxes.dart';
import 'package:project85/core/utils/night_shift_helper.dart';
import 'package:project85/core/utils/calculators.dart';
import 'package:project85/features/gamification/presentation/providers/gamification_provider.dart';
import 'package:project85/features/diet/presentation/providers/diet_provider.dart';
import 'package:project85/features/water/presentation/providers/water_provider.dart';
import 'package:project85/features/habits/presentation/providers/habit_provider.dart';
import 'package:project85/features/workout/presentation/providers/workout_provider.dart';
import 'package:project85/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:project85/features/measurements/domain/measurement.dart';
import 'package:project85/features/measurements/presentation/providers/measurement_provider.dart';
import 'package:project85/features/photos/presentation/providers/photo_provider.dart';
import 'package:project85/main.dart';
import 'package:project85/features/dashboard/presentation/screens/main_shell.dart';

void main() {
  group('NightShiftHelper Unit Tests', () {
    test('Boundary test - Before 5 PM belongs to previous tracking day', () {
      final localTime = DateTime(2026, 6, 7, 16, 30);
      final trackingDay = NightShiftHelper.getTrackingDay(localTime, startHour: 17);
      
      expect(trackingDay.year, equals(2026));
      expect(trackingDay.month, equals(6));
      expect(trackingDay.day, equals(6));
    });

    test('Boundary test - After 5 PM belongs to current tracking day', () {
      final localTime = DateTime(2026, 6, 7, 17, 15);
      final trackingDay = NightShiftHelper.getTrackingDay(localTime, startHour: 17);
      
      expect(trackingDay.year, equals(2026));
      expect(trackingDay.month, equals(6));
      expect(trackingDay.day, equals(7));
    });

    test('isSameTrackingDay check across midnight boundaries', () {
      final time1 = DateTime(2026, 6, 7, 23, 30);
      final time2 = DateTime(2026, 6, 8, 03, 15);
      final time3 = DateTime(2026, 6, 8, 18, 00);

      expect(NightShiftHelper.isSameTrackingDay(time1, time2, startHour: 17), isTrue);
      expect(NightShiftHelper.isSameTrackingDay(time1, time3, startHour: 17), isFalse);
    });
  });

  group('HealthCalculators Unit Tests', () {
    test('BMI Calculation and Category', () {
      final bmi = HealthCalculators.calculateBMI(108.0, 180.0);
      expect(bmi, closeTo(33.33, 0.05));
      expect(HealthCalculators.getBMICategory(bmi), equals('Obese'));
    });

    test('BMR Mifflin-St Jeor Calculation', () {
      final bmr = HealthCalculators.calculateBMR(108.0, 180.0, 32, true);
      expect(bmr, equals(2050.0));
    });

    test('Daily Protein Estimator', () {
      final proteinGoal = HealthCalculators.calculateDailyProteinGoal(108.0);
      expect(proteinGoal, equals(216.0));
    });
  });

  group('State Providers Integration Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('project85_test_dir');
      Hive.init(tempDir.path);
      await Hive.openBox(HiveBoxes.userProfile);
      await Hive.openBox(HiveBoxes.dietLogs);
      await Hive.openBox(HiveBoxes.waterLogs);
      await Hive.openBox(HiveBoxes.workoutLogs);
      await Hive.openBox(HiveBoxes.habitLogs);
      await Hive.openBox(HiveBoxes.appSettings);
      await Hive.openBox(HiveBoxes.weightHistory);
      await Hive.openBox(HiveBoxes.measurementHistory);
      await Hive.openBox(HiveBoxes.progressPhotos);
    });

    tearDown(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('UserProfileNotifier - XP, Streaks & Badges evaluate', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(userProfileProvider.notifier);
      
      // Verify initial profile values
      expect(container.read(userProfileProvider).xp, equals(0));
      expect(container.read(userProfileProvider).level, equals(1));

      // Add XP to level up (needs 100 XP to reach Level 2)
      bool didLevelUp = await notifier.addXp(120);
      expect(didLevelUp, isTrue);
      expect(container.read(userProfileProvider).level, equals(2));
      expect(container.read(userProfileProvider).xp, equals(20)); // 120 - 100 = 20

      // Add more XP (needs 150 XP for Level 3)
      didLevelUp = await notifier.addXp(150);
      expect(didLevelUp, isTrue);
      expect(container.read(userProfileProvider).level, equals(3));
      expect(container.read(userProfileProvider).xp, equals(20)); // 20 + 150 - 150 = 20

      // Test weight update
      await notifier.updateWeight(103.0);
      expect(container.read(userProfileProvider).currentWeight, equals(103.0));

      // Test streak calculation (consecutive tracking)
      await notifier.logDailyActivity('2026-06-07');
      expect(container.read(userProfileProvider).overallStreak, equals(1));
      
      await notifier.logDailyActivity('2026-06-08');
      expect(container.read(userProfileProvider).overallStreak, equals(2));

      // Non-consecutive tracking resets streak to 1
      await notifier.logDailyActivity('2026-06-10');
      expect(container.read(userProfileProvider).overallStreak, equals(1));
    });

    test('DietNotifier - Log creation and meal toggle completion', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final dietNotifier = container.read(dietProvider.notifier);
      final profile = container.read(userProfileProvider);
      final dateStr = DateFormat('yyyy-MM-dd').format(
        NightShiftHelper.getTrackingDay(DateTime.now(), startHour: profile.startHour)
      );

      // Verify that diet log initialized properly
      expect(container.read(dietProvider).currentLog.trackingDate, equals(dateStr));
      expect(container.read(dietProvider).currentLog.meals.length, equals(5));

      // Toggle first meal (should give 10 XP)
      final firstMealId = container.read(dietProvider).currentLog.meals.first.id;
      await dietNotifier.toggleMealCompletion(firstMealId, true);

      expect(container.read(dietProvider).currentLog.meals.first.isCompleted, isTrue);
      expect(container.read(userProfileProvider).xp, equals(10));

      // Update macros for first meal
      await dietNotifier.updateMealMacros(firstMealId, 450, 35, 45, 10);
      expect(container.read(dietProvider).currentLog.meals.first.calories, equals(450.0));
      expect(container.read(dietProvider).currentLog.meals.first.protein, equals(35.0));

      // Update notes
      await dietNotifier.updateMealNotes(firstMealId, "Ate high protein snack");
      expect(container.read(dietProvider).currentLog.meals.first.notes, equals("Ate high protein snack"));
    });

    test('WaterNotifier - Intake and goal checks', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final waterNotifier = container.read(waterProvider.notifier);
      
      expect(container.read(waterProvider).intakeMl, equals(0));

      // Add 500ml
      await waterNotifier.logWater(500);
      expect(container.read(waterProvider).intakeMl, equals(500));

      // Add 4000ml to hit the goal (Goal is default 4L)
      await waterNotifier.logWater(3500);
      expect(container.read(waterProvider).intakeMl, equals(4000));
      expect(container.read(waterProvider).isGoalAchieved, isTrue);
      
      // Goal achieved should reward 15 XP
      expect(container.read(userProfileProvider).xp, equals(15));
    });

    test('HabitNotifier - Completion toggles and synchronization', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final habitNotifier = container.read(habitProvider.notifier);
      expect(container.read(habitProvider).habits.length, equals(7));

      // Sleep habit toggle gives 10 XP
      await habitNotifier.toggleHabit('sleep');
      expect(container.read(habitProvider).habits.firstWhere((h) => h.id == 'sleep').isCompleted, isTrue);
      expect(container.read(userProfileProvider).xp, equals(10));

      // Sync water and workout completions
      await habitNotifier.syncWaterAndWorkout(true, true);
      expect(container.read(habitProvider).habits.firstWhere((h) => h.id == 'water_4l').isCompleted, isTrue);
      expect(container.read(habitProvider).habits.firstWhere((h) => h.id == 'workout').isCompleted, isTrue);
    });

    test('WorkoutNotifier - Presets selection and completion logic', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final workoutNotifier = container.read(workoutProvider.notifier);
      expect(container.read(workoutProvider).currentSession, isNull);

      // Start Lower Body workout
      await workoutNotifier.startWorkout('Workout A (Lower Body)');
      
      final session = container.read(workoutProvider).currentSession;
      expect(session, isNotNull);
      expect(session!.name, equals('Workout A (Lower Body)'));
      expect(session.exercises.length, equals(4));

      // Toggle first set of first exercise
      await workoutNotifier.toggleSetCompletion(0, 0);
      expect(container.read(workoutProvider).currentSession!.exercises[0].sets[0].isCompleted, isTrue);

      // Verify that session is not fully complete yet
      expect(container.read(workoutProvider).currentSession!.isCompleted, isFalse);

      // Mark all remaining sets as completed to trigger workout success
      final currentSession = container.read(workoutProvider).currentSession!;
      for (int i = 0; i < currentSession.exercises.length; i++) {
        for (int j = 0; j < currentSession.exercises[i].sets.length; j++) {
          if (i == 0 && j == 0) continue; // Already toggled
          await workoutNotifier.toggleSetCompletion(i, j);
        }
      }

      // Session should now be marked completed and award 25 XP
      expect(container.read(workoutProvider).currentSession!.isCompleted, isTrue);
      expect(container.read(userProfileProvider).xp, equals(25));
    });

    test('DashboardProvider - Compliance calculation aggregator', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final dietNotifier = container.read(dietProvider.notifier);
      final waterNotifier = container.read(waterProvider.notifier);
      final habitNotifier = container.read(habitProvider.notifier);

      // 1. Initial State: Compliance score should be 0.0
      expect(container.read(dashboardProvider).complianceScore, equals(0.0));

      // 2. Perform actions and check compliance increments:
      // Diet (30% weight) - complete all 5 meals
      final meals = container.read(dietProvider).currentLog.meals;
      for (var meal in meals) {
        await dietNotifier.toggleMealCompletion(meal.id, true);
      }
      // Water (20% weight) - hit goal
      await waterNotifier.logWater(4000);
      
      // Habits (20% weight) - check 3/7 habits (42.86% rate)
      await habitNotifier.toggleHabit('sleep');
      await habitNotifier.toggleHabit('no_sugar');
      await habitNotifier.toggleHabit('no_junk');

      // Compliance = Diet(1.0 * 0.3) + Water(1.0 * 0.2) + Habits((3/7) * 0.2) + Workout(0.0 * 0.3)
      // Compliance = 0.3 + 0.2 + (0.42857 * 0.2) = 0.5 + 0.085714 = 0.5857 (58.57%)
      expect(container.read(dashboardProvider).complianceScore, closeTo(0.5857, 0.01));
    });

    test('MeasurementNotifier - Add and delete measurements', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(measurementProvider.notifier);
      expect(container.read(measurementProvider), isEmpty);

      final entry1 = BodyMeasurement(
        trackingDate: '2026-06-07',
        weightKg: 108.0,
        waistCm: 110.0,
        neckCm: 42.0,
        chestCm: 115.0,
      );

      final entry2 = BodyMeasurement(
        trackingDate: '2026-06-08',
        weightKg: 107.0,
        waistCm: 109.0,
        neckCm: 42.0,
        chestCm: 114.0,
      );

      // Add first measurement
      await notifier.addMeasurement(entry1);
      expect(container.read(measurementProvider).length, equals(1));
      expect(container.read(measurementProvider).first.weightKg, equals(108.0));
      expect(container.read(userProfileProvider).currentWeight, equals(108.0));

      // Add second measurement (newer date)
      await notifier.addMeasurement(entry2);
      expect(container.read(measurementProvider).length, equals(2));
      expect(container.read(measurementProvider).first.weightKg, equals(107.0)); // Sorted descending by date
      expect(container.read(userProfileProvider).currentWeight, equals(107.0));

      // Delete second measurement, should rollback currentWeight to entry1
      await notifier.deleteMeasurement('2026-06-08');
      expect(container.read(measurementProvider).length, equals(1));
      expect(container.read(userProfileProvider).currentWeight, equals(108.0));
    });

    test('PhotoNotifier - Add and delete progress photos', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(photoProvider.notifier);
      expect(container.read(photoProvider), isEmpty);

      // Add front photo
      await notifier.addPhoto('2026-06-07', 'front', '/path/to/front.jpg');
      expect(container.read(photoProvider).length, equals(1));
      expect(container.read(photoProvider).first.frontPath, equals('/path/to/front.jpg'));
      expect(container.read(photoProvider).first.sidePath, isNull);

      // Add side photo on same day
      await notifier.addPhoto('2026-06-07', 'side', '/path/to/side.jpg');
      expect(container.read(photoProvider).length, equals(1)); // Still 1 entry
      expect(container.read(photoProvider).first.frontPath, equals('/path/to/front.jpg'));
      expect(container.read(photoProvider).first.sidePath, equals('/path/to/side.jpg'));

      // Delete photo entry
      await notifier.deletePhotoEntry('2026-06-07');
      expect(container.read(photoProvider), isEmpty);
    });
  });

  group('UI Widget Integration Tests', () {
    testWidgets('UI Widget Test - Pump App and Navigate Tabs', (WidgetTester tester) async {
      final temp = await Directory.systemTemp.createTemp('widget_test_hive_ui1');
      Hive.init(temp.path);
      await Hive.openBox(HiveBoxes.userProfile);
      await Hive.openBox(HiveBoxes.dietLogs);
      await Hive.openBox(HiveBoxes.waterLogs);
      await Hive.openBox(HiveBoxes.workoutLogs);
      await Hive.openBox(HiveBoxes.habitLogs);
      await Hive.openBox(HiveBoxes.appSettings);
      await Hive.openBox(HiveBoxes.weightHistory);
      await Hive.openBox(HiveBoxes.measurementHistory);
      await Hive.openBox(HiveBoxes.progressPhotos);

      // Pump the App
      await tester.pumpWidget(
        const ProviderScope(
          child: Project85App(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Verify that DashboardScreen is rendered
      expect(find.text("TODAY'S COMPLIANCE SCORE"), findsOneWidget);

      // Tap on Diet Tab
      await tester.tap(find.byIcon(Icons.restaurant_outlined));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text("DAILY DIET TRACKER"), findsOneWidget);

      // Tap first meal checkbox
      expect(find.byType(Checkbox).first, findsOneWidget);
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump(const Duration(milliseconds: 100));

      // Tap on Workout Tab
      await tester.tap(find.byIcon(Icons.fitness_center_outlined));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text("WORKOUT TRACKER"), findsOneWidget);

      // Tap on Water Tab
      await tester.tap(find.byIcon(Icons.water_drop_outlined));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text("WATER & HABITS"), findsOneWidget);

      // Tap water log button
      expect(find.text("+250 ml"), findsOneWidget);
      await tester.tap(find.text("+250 ml"));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap on Coach tab
      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text("AI COACH CORE"), findsOneWidget);

      // Tap on Settings icon button in AppBar
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text("SETTINGS & TOOLS"), findsOneWidget);

      // Cleanup
      await Hive.close();
      await temp.delete(recursive: true);
    });

    testWidgets('UI Widget Test - Craving Guard activates AI Coach', (WidgetTester tester) async {
      final temp = await Directory.systemTemp.createTemp('widget_test_hive_ui2');
      Hive.init(temp.path);
      await Hive.openBox(HiveBoxes.userProfile);
      await Hive.openBox(HiveBoxes.dietLogs);
      await Hive.openBox(HiveBoxes.waterLogs);
      await Hive.openBox(HiveBoxes.workoutLogs);
      await Hive.openBox(HiveBoxes.habitLogs);
      await Hive.openBox(HiveBoxes.appSettings);
      await Hive.openBox(HiveBoxes.weightHistory);
      await Hive.openBox(HiveBoxes.measurementHistory);
      await Hive.openBox(HiveBoxes.progressPhotos);

      await tester.pumpWidget(
        const ProviderScope(
          child: Project85App(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Find "ACTIVATE" button inside Craving Guard
      final activateButton = find.text("ACTIVATE");
      expect(activateButton, findsOneWidget);

      // Tap it
      await tester.tap(activateButton);
      await tester.pump(const Duration(milliseconds: 100));

      // Should now be on AI Coach Screen
      expect(find.text("AI COACH CORE"), findsOneWidget);

      await Hive.close();
      await temp.delete(recursive: true);
    });
  });
}
