import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../gamification/presentation/providers/gamification_provider.dart';
import '../../../diet/presentation/providers/diet_provider.dart';
import '../../../water/presentation/providers/water_provider.dart';
import '../../../workout/presentation/providers/workout_provider.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../../core/utils/night_shift_helper.dart';

class DashboardData {
  final double complianceScore; // 0.0 to 1.0
  final double weightRemaining; // kg
  final double weightProgressPercent; // 0.0 to 1.0
  final DateTime targetCompletionDate;
  final bool isDietAdherent;
  final bool isWorkoutCompleted;
  final double waterIntakePercent;
  final double habitsCheckedPercent;

  DashboardData({
    required this.complianceScore,
    required this.weightRemaining,
    required this.weightProgressPercent,
    required this.targetCompletionDate,
    required this.isDietAdherent,
    required this.isWorkoutCompleted,
    required this.waterIntakePercent,
    required this.habitsCheckedPercent,
  });
}

final dashboardProvider = Provider<DashboardData>((ref) {
  final profile = ref.watch(userProfileProvider);
  final dietState = ref.watch(dietProvider);
  final waterLog = ref.watch(waterProvider);
  final workoutState = ref.watch(workoutProvider);
  final habitsLog = ref.watch(habitProvider);

  // 1. Calculate compliance score
  // - Diet meals checked: 30%
  // - Workout completed: 30%
  // - Water goal hit: 20%
  // - Habits checked: 20%
  double dietWeight = 0.3;
  double workoutWeight = 0.3;
  double waterWeight = 0.2;
  double habitsWeight = 0.2;

  double dietScore = dietState.currentLog.complianceRate;
  double workoutScore = (workoutState.currentSession?.isCompleted ?? false) ? 1.0 : 0.0;
  double waterScore = waterLog.progressPercentage;
  double habitsScore = habitsLog.complianceRate;

  double overallCompliance = (dietScore * dietWeight) +
      (workoutScore * workoutWeight) +
      (waterScore * waterWeight) +
      (habitsScore * habitsWeight);

  // Sync water and workout into habits checklist in background if needed
  // We can do this in a post-frame callback or directly in UI triggers, 
  // but to keep it simple, we just calculate scores independently.

  // 2. Weight metrics
  double remaining = (profile.currentWeight - profile.targetWeight).clamp(0.0, 500.0);
  
  double totalWeightToLose = profile.startWeight - profile.targetWeight;
  double weightLost = profile.startWeight - profile.currentWeight;
  double weightProgress = 0.0;
  if (totalWeightToLose > 0) {
    weightProgress = (weightLost / totalWeightToLose).clamp(0.0, 1.0);
  }

  // 3. Target completion date (0.7kg per week)
  DateTime targetDate = NightShiftHelper.calculateTargetDate(
    profile.currentWeight,
    profile.targetWeight,
    DateTime.now(),
  );

  return DashboardData(
    complianceScore: overallCompliance,
    weightRemaining: remaining,
    weightProgressPercent: weightProgress,
    targetCompletionDate: targetDate,
    isDietAdherent: dietScore >= 1.0,
    isWorkoutCompleted: workoutScore >= 1.0,
    waterIntakePercent: waterScore,
    habitsCheckedPercent: habitsScore,
  );
});
