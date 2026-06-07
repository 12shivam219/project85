import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/workout_provider.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/exercise.dart';
import 'exercise_db_screen.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  bool _showCrushedAnimation = false;

  void _triggerCrushedAnimation() {
    setState(() {
      _showCrushedAnimation = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showCrushedAnimation = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final workoutState = ref.watch(workoutProvider);
    final session = workoutState.currentSession;
    
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: workoutState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : session == null
                    ? _buildWorkoutPicker(context)
                    : _buildWorkoutTracker(context, session, workoutState.exerciseDb),
          ),
          if (_showCrushedAnimation) _buildCrushedOverlay(context),
        ],
      ),
    );
  }

  Widget _buildWorkoutPicker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("WORKOUT TRACKER", style: Theme.of(context).textTheme.displayMedium),
              IconButton(
                icon: const Icon(Icons.menu_book, color: AppColors.primary),
                tooltip: "Exercise Library",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ExerciseDbScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Select today's training split. Consistency preserves muscle mass during fat loss.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                _buildWorkoutPickerCard(
                  context,
                  "Workout A (Lower Body)",
                  "Target: Legs, Glutes, posterior chain focus.",
                  "Goblet Squat, RDL, Walking Lunge, Glute Bridge",
                  Colors.orange,
                ),
                const SizedBox(height: 16),
                _buildWorkoutPickerCard(
                  context,
                  "Workout B (Upper Body)",
                  "Target: Chest, Back, Shoulders, arms focus.",
                  "Bent Over Row, Shoulder Press, Chest Fly, Band Pulls",
                  Colors.blue,
                ),
                const SizedBox(height: 16),
                _buildWorkoutPickerCard(
                  context,
                  "Workout C (Full Body / HIIT)",
                  "Target: Full body resistance & metabolic burn.",
                  "Deadlift, Burpees, Shoulder Press, Walking Lunge",
                  Colors.purple,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildWorkoutPickerCard(
    BuildContext context,
    String name,
    String description,
    String exercises,
    Color accentColor,
  ) {
    return GlassCard(
      onTap: () {
        ref.read(workoutProvider.notifier).startWorkout(name);
      },
      child: Row(
        children: [
          Container(
            width: 8,
            height: 90,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                ),
                const SizedBox(height: 8),
                Text(
                  "Exercises: $exercises",
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppColors.primary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondaryDark),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildWorkoutTracker(BuildContext context, dynamic session, List<Exercise> db) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.name.toUpperCase(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      "Shift Date: ${session.trackingDate}",
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _showResetConfirm(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red.withOpacity(0.15),
                  foregroundColor: AppColors.red,
                  elevation: 0,
                  side: const BorderSide(color: AppColors.red),
                ),
                child: const Text("Reset", style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: session.progressPercentage,
                    minHeight: 8,
                    backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
                    color: AppColors.green,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "${(session.progressPercentage * 100).round()}% Completed",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.green),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Exercises Logs
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: session.exercises.length,
              itemBuilder: (context, exIndex) {
                final exLog = session.exercises[exIndex];
                final exerciseInfo = db.firstWhere((e) => e.id == exLog.exerciseId);

                return _buildExerciseCard(context, exLog, exerciseInfo, exIndex);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, dynamic exLog, Exercise info, int exIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        borderColor: exLog.isCompleted ? AppColors.green.withOpacity(0.5) : null,
        backgroundColor: exLog.isCompleted ? AppColors.green.withOpacity(0.03) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise header with name and details button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(info.animation, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      exLog.exerciseName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _showExerciseGuide(context, info),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Guide",
                      style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Sets header
            const Row(
              children: [
                Expanded(flex: 2, child: Text("Set", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark))),
                Expanded(flex: 3, child: Text("Weight (kg)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark))),
                Expanded(flex: 3, child: Text("Reps", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark))),
                Expanded(flex: 4, child: SizedBox()),
              ],
            ),
            const Divider(height: 12, color: AppColors.borderDark),

            // Sets list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: exLog.sets.length,
              itemBuilder: (context, setIndex) {
                final set = exLog.sets[setIndex];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      // Set number
                      Expanded(
                        flex: 2,
                        child: Text(
                          "${set.setNumber}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: set.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      
                      // Weight Input/Display
                      Expanded(
                        flex: 3,
                        child: GestureDetector(
                          onTap: set.isCompleted ? null : () => _showEditSetDialog(context, exIndex, setIndex, set.weightKg, set.reps),
                          child: Text(
                            "${set.weightKg} kg",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration: set.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                      ),

                      // Reps Input/Display
                      Expanded(
                        flex: 3,
                        child: GestureDetector(
                          onTap: set.isCompleted ? null : () => _showEditSetDialog(context, exIndex, setIndex, set.weightKg, set.reps),
                          child: Text(
                            "${set.reps} reps",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration: set.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                      ),

                      // Log complete button
                      Expanded(
                        flex: 4,
                        child: ElevatedButton(
                          onPressed: () async {
                            final stateBefore = ref.read(workoutProvider);
                            final wasCompleted = stateBefore.currentSession?.isCompleted ?? false;

                            await ref.read(workoutProvider.notifier).toggleSetCompletion(exIndex, setIndex);
                            
                            final stateAfter = ref.read(workoutProvider);
                            if (stateAfter.currentSession != null && 
                                !wasCompleted && 
                                stateAfter.currentSession!.isCompleted) {
                              _triggerCrushedAnimation();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: set.isCompleted
                                ? AppColors.green
                                : AppColors.primary.withOpacity(0.1),
                            foregroundColor: set.isCompleted
                                ? Colors.black
                                : AppColors.primary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                          ),
                          child: Text(
                            set.isCompleted ? "COMPLETE ✓" : "LOG SET",
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showExerciseGuide(BuildContext context, Exercise info) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(info.animation, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Text(
                    info.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "Category: ${info.category}",
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: info.targetMuscles.map((m) => Chip(
                  label: Text(m, style: const TextStyle(fontSize: 11)),
                  backgroundColor: AppColors.cardDark,
                )).toList(),
              ),
              const SizedBox(height: 16),
              const Text("Instructions:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                info.instructions,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondaryDark, height: 1.4),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showEditSetDialog(BuildContext context, int exIndex, int setIndex, double currentWeight, int currentReps) {
    final weightController = TextEditingController(text: currentWeight.toString());
    final repsController = TextEditingController(text: currentReps.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Set Details"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Weight (kg)"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: repsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Reps"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final w = double.tryParse(weightController.text) ?? currentWeight;
                final r = int.tryParse(repsController.text) ?? currentReps;
                ref.read(workoutProvider.notifier).updateSetWeightAndReps(exIndex, setIndex, w, r);
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _showResetConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Reset Workout?"),
          content: const Text("This will delete all completed sets logged for today's session. Are you sure?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                ref.read(workoutProvider.notifier).resetWorkout();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
              child: const Text("Delete Workout"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCrushedOverlay(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "🔥",
            style: TextStyle(fontSize: 80),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 16),
          const Text(
            "WORKOUT CRUSHED",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.orange,
              letterSpacing: 2,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 8),
          const Text(
            "+25 XP Awarded • Streak Maintained",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}
