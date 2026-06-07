import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/diet_provider.dart';
import '../../../gamification/presentation/providers/gamification_provider.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/widgets/glass_card.dart';

class DietScreen extends ConsumerWidget {
  const DietScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dietState = ref.watch(dietProvider);
    final profile = ref.watch(userProfileProvider);
    
    final currentLog = dietState.currentLog;
    
    // Macro progress percents
    final calPercent = (currentLog.totalCalories / profile.dailyCaloriesGoalKcal).clamp(0.0, 1.0);
    final proPercent = (currentLog.totalProtein / profile.dailyProteinGoalGrams).clamp(0.0, 1.0);
    final carbPercent = (currentLog.totalCarbs / 200.0).clamp(0.0, 1.0); // Arbitrary carbs goal: 200g
    final fatPercent = (currentLog.totalFat / 70.0).clamp(0.0, 1.0);    // Arbitrary fat goal: 70g

    return Scaffold(
      body: SafeArea(
        child: dietState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("DAILY DIET TRACKER", style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 4),
                    Text(
                      "Log your meals strictly to maintain compliance.",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),

                    // 1. Calories & Macros summary card
                    _buildNutritionSummary(context, currentLog, profile, calPercent, proPercent, carbPercent, fatPercent),
                    const SizedBox(height: 24),

                    // 2. Meals checklist
                    Text("TODAY'S SHIFT MEALS", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: currentLog.meals.length,
                      itemBuilder: (context, index) {
                        final meal = currentLog.meals[index];
                        return _buildMealTile(context, ref, meal);
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildNutritionSummary(
    BuildContext context,
    dynamic currentLog,
    dynamic profile,
    double calPercent,
    double proPercent,
    double carbPercent,
    double fatPercent,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("NUTRITION TRACKER", style: Theme.of(context).textTheme.titleMedium),
              Text(
                "${currentLog.totalCalories.toStringAsFixed(0)} / ${profile.dailyCaloriesGoalKcal.toStringAsFixed(0)} kcal",
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: calPercent,
              minHeight: 10,
              backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Macros columns
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroProgress(context, "Protein", currentLog.totalProtein, profile.dailyProteinGoalGrams, "g", proPercent, AppColors.green),
              _buildMacroProgress(context, "Carbs", currentLog.totalCarbs, 200.0, "g", carbPercent, AppColors.info),
              _buildMacroProgress(context, "Fat", currentLog.totalFat, 70.0, "g", fatPercent, AppColors.orange),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildMacroProgress(
    BuildContext context,
    String label,
    double current,
    double target,
    String unit,
    double percent,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          "${current.toStringAsFixed(0)}$unit / ${target.toStringAsFixed(0)}$unit",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 90,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 5,
              backgroundColor: AppColors.borderDark.withOpacity(0.3),
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealTile(BuildContext context, WidgetRef ref, dynamic meal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        backgroundColor: meal.isCompleted
            ? AppColors.green.withOpacity(isDark ? 0.05 : 0.03)
            : null,
        borderColor: meal.isCompleted
            ? AppColors.green.withOpacity(0.4)
            : null,
        child: Row(
          children: [
            // Checkbox
            Checkbox(
              value: meal.isCompleted,
              onChanged: (val) {
                if (val != null) {
                  ref.read(dietProvider.notifier).toggleMealCompletion(meal.id, val);
                }
              },
            ),
            const SizedBox(width: 8),

            // Meal details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      decoration: meal.isCompleted ? TextDecoration.lineThrough : null,
                      color: meal.isCompleted
                          ? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 12, color: AppColors.textSecondaryDark),
                      const SizedBox(width: 4),
                      Text(
                        "Scheduled: ${meal.scheduledTime}",
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                      ),
                      if (meal.isCompleted && meal.completionTime != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.done_all, size: 12, color: AppColors.green),
                        const SizedBox(width: 4),
                        Text(
                          "Eaten: ${meal.completionTime}",
                          style: const TextStyle(fontSize: 11, color: AppColors.green, fontWeight: FontWeight.bold),
                        ),
                      ]
                    ],
                  ),
                  if (meal.notes.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      "📝 ${meal.notes}",
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]
                ],
              ),
            ),

            // Macros summary & Notes button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${meal.calories.round()} kcal",
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Text(
                  "P: ${meal.protein.round()}g | C: ${meal.carbs.round()}g",
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryDark),
                ),
                const SizedBox(height: 4),
                
                // Notes button
                GestureDetector(
                  onTap: () => _showNotesDialog(context, ref, meal),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, size: 10, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text("Edit", style: TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  void _showNotesDialog(BuildContext context, WidgetRef ref, dynamic meal) {
    final notesController = TextEditingController(text: meal.notes);
    final caloriesController = TextEditingController(text: meal.calories.toStringAsFixed(0));
    final proteinController = TextEditingController(text: meal.protein.toStringAsFixed(0));
    final carbsController = TextEditingController(text: meal.carbs.toStringAsFixed(0));
    final fatController = TextEditingController(text: meal.fat.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit ${meal.name}"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: "Custom Items eaten & Notes",
                    hintText: "E.g., chicken breast, oats, coffee",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: caloriesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Calories", suffixText: "kcal"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: proteinController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Protein", suffixText: "g"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: carbsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Carbs", suffixText: "g"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: fatController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Fat", suffixText: "g"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final cal = double.tryParse(caloriesController.text) ?? meal.calories;
                final pro = double.tryParse(proteinController.text) ?? meal.protein;
                final carb = double.tryParse(carbsController.text) ?? meal.carbs;
                final fat = double.tryParse(fatController.text) ?? meal.fat;
                
                ref.read(dietProvider.notifier).updateMealNotes(meal.id, notesController.text);
                ref.read(dietProvider.notifier).updateMealMacros(meal.id, cal, pro, carb, fat);
                
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}
