import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/water_provider.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../workout/presentation/providers/workout_provider.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/widgets/glass_card.dart';

class WaterScreen extends ConsumerWidget {
  const WaterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterLog = ref.watch(waterProvider);
    final habitsLog = ref.watch(habitProvider);

    // Sync water completion into habits log automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workoutCompleted = ref.read(workoutProvider).currentSession?.isCompleted ?? false;
      ref.read(habitProvider.notifier).syncWaterAndWorkout(
        waterLog.isGoalAchieved,
        workoutCompleted,
      );
    });

    final currentIntakeLiters = waterLog.intakeMl / 1000.0;
    final goalLiters = waterLog.goalMl / 1000.0;
    final fillFraction = waterLog.progressPercentage;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("WATER & HABITS", style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 4),
              Text(
                "Hydration and habits are crucial for metabolic speed.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Layout: Water Bottle on top/left, quick buttons next to it
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Visual Water Bottle
                  _buildVisualBottle(context, fillFraction, currentIntakeLiters, goalLiters),
                  const SizedBox(width: 24),
                  
                  // Quick Log Buttons
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "LOG WATER",
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.info,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildQuickLogButton(ref, 250, "Cup"),
                        const SizedBox(height: 8),
                        _buildQuickLogButton(ref, 500, "Glass"),
                        const SizedBox(height: 8),
                        _buildQuickLogButton(ref, 750, "Shaker"),
                        const SizedBox(height: 8),
                        _buildQuickLogButton(ref, 1000, "Flask (1L)"),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Daily Habits Checklist
              Text("DAILY COMPLIANCE HABITS", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                "Each checked habit adds XP and raises your daily score.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: habitsLog.habits.length,
                itemBuilder: (context, index) {
                  final habit = habitsLog.habits[index];
                  // Disable editing water/workout manually since they sync with active logs
                  final isSyncedHabit = habit.id == 'water_4l' || habit.id == 'workout';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      backgroundColor: habit.isCompleted ? AppColors.info.withOpacity(0.05) : null,
                      borderColor: habit.isCompleted ? AppColors.info.withOpacity(0.4) : null,
                      child: Row(
                        children: [
                          Checkbox(
                            value: habit.isCompleted,
                            onChanged: isSyncedHabit
                                ? null // Managed automatically
                                : (val) {
                                    ref.read(habitProvider.notifier).toggleHabit(habit.id);
                                  },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  habit.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    decoration: habit.isCompleted ? TextDecoration.lineThrough : null,
                                    color: habit.isCompleted ? AppColors.textSecondaryDark : null,
                                  ),
                                ),
                                Text(
                                  habit.description,
                                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryDark),
                                ),
                              ],
                            ),
                          ),
                          if (isSyncedHabit)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text("Auto-Sync", style: TextStyle(color: AppColors.primary, fontSize: 8, fontWeight: FontWeight.bold)),
                            )
                          else
                            Text(
                              habit.id == 'sleep' ? "+10 XP" : "+5 XP",
                              style: const TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisualBottle(BuildContext context, double fillFraction, double currentL, double goalL) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      width: 140,
      height: 250,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Bottle shape
          Expanded(
            child: Container(
              width: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 2.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Liquid level filling up
                    AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      heightFactor: fillFraction,
                      widthFactor: 1.0,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF2F80ED), Color(0xFF00B0FF)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ),
                    
                    // Wave graphic/bubble sparkles
                    if (fillFraction > 0)
                      Positioned(
                        bottom: 40,
                        child: const Icon(Icons.bubble_chart, color: Colors.white24, size: 24)
                            .animate(onPlay: (c) => c.repeat())
                            .slideY(begin: 1, end: -1, duration: 2.seconds)
                            .fadeOut(),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "${currentL.toStringAsFixed(1)}L",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.info),
          ),
          Text(
            "Target: ${goalL.toStringAsFixed(0)}L",
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryDark),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLogButton(WidgetRef ref, int amountMl, String unitLabel) {
    return ElevatedButton(
      onPressed: () {
        ref.read(waterProvider.notifier).logWater(amountMl);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.info.withOpacity(0.1),
        foregroundColor: AppColors.info,
        elevation: 0,
        minimumSize: const Size(double.infinity, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("+$amountMl ml", style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(unitLabel, style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryDark)),
        ],
      ),
    );
  }
}
