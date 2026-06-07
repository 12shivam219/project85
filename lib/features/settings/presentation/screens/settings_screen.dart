import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../gamification/presentation/providers/gamification_provider.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/utils/calculators.dart';
import '../../../../core/utils/file_exporter.dart';
import '../../../../core/database/hive_boxes.dart';
import '../../../measurements/presentation/providers/measurement_provider.dart';
import '../../../diet/domain/meal.dart';
import '../../../workout/domain/workout_session.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final box = Hive.box(HiveBoxes.appSettings);
    _apiKeyController.text = box.get('openai_api_key', defaultValue: '');
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("SETTINGS & TOOLS", style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 4),
              Text(
                "Configure your routine parameters, access calculators, and export report files.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // 1. User Profile Settings
              _buildSectionTitle("PROFILE CONFIGURATION"),
              const SizedBox(height: 8),
              _buildProfileSettingsCard(context, profile),
              const SizedBox(height: 24),

              // 2. Night Shift Mode Settings
              _buildSectionTitle("NIGHT-SHIFT SCHEDULE"),
              const SizedBox(height: 8),
              _buildNightShiftSettingsCard(context, profile),
              const SizedBox(height: 24),

              // 3. Health Calculators
              _buildSectionTitle("METRIC ESTIMATORS"),
              const SizedBox(height: 8),
              _buildCalculatorsCard(context, profile),
              const SizedBox(height: 24),

              // 4. OpenAI Integration
              _buildSectionTitle("AI ENGINE CONFIG"),
              const SizedBox(height: 8),
              _buildOpenAIConfigCard(context),
              const SizedBox(height: 24),

              // 5. Data Export
              _buildSectionTitle("DATA EXPORTS"),
              const SizedBox(height: 8),
              _buildExportCard(context),
              const SizedBox(height: 24),

              // 6. Hard Reset Database
              ElevatedButton(
                onPressed: () => _showResetConfirm(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text("RESET ALL APP DATA", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildProfileSettingsCard(BuildContext context, dynamic profile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      child: Column(
        children: [
          _buildSettingsRow(context, "Username", profile.name, Icons.person, () => _showEditProfileDialog(context)),
          const Divider(height: 20, color: AppColors.borderDark),
          _buildSettingsRow(context, "Age", "${profile.age} years", Icons.calendar_today, () => _showEditProfileDialog(context)),
          const Divider(height: 20, color: AppColors.borderDark),
          _buildSettingsRow(context, "Height", "${profile.heightCm} cm", Icons.height, () => _showEditProfileDialog(context)),
          const Divider(height: 20, color: AppColors.borderDark),
          _buildSettingsRow(context, "Target Weight", "${profile.targetWeight} kg", Icons.track_changes, () => _showEditProfileDialog(context)),
          const Divider(height: 20, color: AppColors.borderDark),
          _buildSettingsRow(
            context,
            "Light Theme Mode",
            isDark ? "Off (Dark theme active)" : "On (Light theme active)",
            Icons.dark_mode,
            () {
              final box = Hive.box(HiveBoxes.appSettings);
              box.put('light_mode', isDark); // Toggle it
              ref.read(themeModeProvider.notifier).state = isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _buildNightShiftSettingsCard(BuildContext context, dynamic profile) {
    return GlassCard(
      child: Column(
        children: [
          _buildSettingsRow(
            context,
            "Day Shift Start Hour",
            "${profile.startHour}:00 (${profile.startHour >= 12 ? '${profile.startHour - 12} PM' : '${profile.startHour} AM'})",
            Icons.wb_twilight,
            () => _showEditProfileDialog(context),
          ),
          const Divider(height: 20, color: AppColors.borderDark),
          _buildSettingsRow(context, "Target Wake Time", profile.wakeTime, Icons.alarm, () => _showEditProfileDialog(context)),
          const Divider(height: 20, color: AppColors.borderDark),
          _buildSettingsRow(context, "Target Sleep Time", profile.sleepTime, Icons.bedtime, () => _showEditProfileDialog(context)),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 350.ms);
  }

  Widget _buildCalculatorsCard(BuildContext context, dynamic profile) {
    // Perform simple estimations
    final bmi = HealthCalculators.calculateBMI(profile.currentWeight, profile.heightCm);
    final bmr = HealthCalculators.calculateBMR(profile.currentWeight, profile.heightCm, profile.age, profile.isMale);
    final tdee = HealthCalculators.calculateTDEE(bmr, 1.375); // Light active multiplier
    final protein = HealthCalculators.calculateDailyProteinGoal(profile.currentWeight);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricRow("Body Mass Index (BMI)", "${bmi.toStringAsFixed(1)} - ${HealthCalculators.getBMICategory(bmi)}"),
          const Divider(height: 16, color: AppColors.borderDark),
          _buildMetricRow("Basal Metabolic Rate (BMR)", "${bmr.toStringAsFixed(0)} kcal/day"),
          const Divider(height: 16, color: AppColors.borderDark),
          _buildMetricRow("Total Energy Expenditure (TDEE)", "${tdee.toStringAsFixed(0)} kcal/day"),
          const Divider(height: 16, color: AppColors.borderDark),
          _buildMetricRow("Estimated Daily Protein Target", "${protein.toStringAsFixed(0)} g/day"),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 350.ms);
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.info)),
      ],
    );
  }

  Widget _buildOpenAIConfigCard(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Paste your OpenAI API Key below to activate real-time AI Coach advice. Leave empty to use local offline coaching.",
            style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark, height: 1.4),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: "sk-proj-...",
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              final box = Hive.box(HiveBoxes.appSettings);
              await box.put('openai_api_key', _apiKeyController.text.trim());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("OpenAI API Key saved successfully.")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 36),
              elevation: 0,
            ),
            child: const Text("Save API Key", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms, duration: 350.ms);
  }

  Widget _buildExportCard(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          _buildSettingsRow(
            context,
            "Export to PDF Report",
            "Generates formal PDF transformation review.",
            Icons.picture_as_pdf,
            () => _handleExport('pdf'),
          ),
          const Divider(height: 20, color: AppColors.borderDark),
          _buildSettingsRow(
            context,
            "Export to Excel Spreadsheet",
            "Tabulates logs in xlsx file format.",
            Icons.table_chart,
            () => _handleExport('excel'),
          ),
          const Divider(height: 20, color: AppColors.borderDark),
          _buildSettingsRow(
            context,
            "Export to CSV File",
            "Comma separated value history sheet.",
            Icons.description,
            () => _handleExport('csv'),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 350.ms);
  }

  Widget _buildSettingsRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(value, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondaryDark),
          ],
        ),
      ),
    );
  }

  void _handleExport(String type) async {
    final measurements = ref.read(measurementProvider);

    // Load full history for exports from Hive logs box
    final dietBox = Hive.box(HiveBoxes.dietLogs);
    List<DailyDietLog> allDiet = [];
    for (var key in dietBox.keys) {
      final data = dietBox.get(key);
      if (data != null) {
        allDiet.add(DailyDietLog.fromMap(Map<String, dynamic>.from(data)));
      }
    }

    final workoutBox = Hive.box(HiveBoxes.workoutLogs);
    List<WorkoutSession> allWorkouts = [];
    for (var key in workoutBox.keys) {
      final data = workoutBox.get(key);
      if (data != null) {
        allWorkouts.add(WorkoutSession.fromMap(Map<String, dynamic>.from(data)));
      }
    }

    if (type == 'pdf') {
      await FileExporter.exportToPDF(measurements: measurements, dietLogs: allDiet, workouts: allWorkouts);
    } else if (type == 'excel') {
      await FileExporter.exportToExcel(measurements: measurements, dietLogs: allDiet, workouts: allWorkouts);
    } else {
      await FileExporter.exportToCSV(measurements: measurements, dietLogs: allDiet, workouts: allWorkouts);
    }
  }

  void _showEditProfileDialog(BuildContext context) {
    final profile = ref.read(userProfileProvider);
    
    final nameController = TextEditingController(text: profile.name);
    final ageController = TextEditingController(text: profile.age.toString());
    final heightController = TextEditingController(text: profile.heightCm.toString());
    final targetController = TextEditingController(text: profile.targetWeight.toString());
    final startHourController = TextEditingController(text: profile.startHour.toString());
    final wakeTimeController = TextEditingController(text: profile.wakeTime);
    final sleepTimeController = TextEditingController(text: profile.sleepTime);
    
    final waterController = TextEditingController(text: profile.dailyWaterGoalLiters.toString());
    final proteinController = TextEditingController(text: profile.dailyProteinGoalGrams.toString());
    final caloriesController = TextEditingController(text: profile.dailyCaloriesGoalKcal.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Settings & Split"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Username")),
                TextField(controller: ageController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Age")),
                TextField(controller: heightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Height (cm)")),
                TextField(controller: targetController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Target Weight (kg)")),
                
                const Divider(height: 24),
                const Text("NIGHT SHIFT HOURLY SETTINGS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                TextField(controller: startHourController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Shift boundary start hour (0-23)")),
                TextField(controller: wakeTimeController, decoration: const InputDecoration(labelText: "Target wake time (HH:MM)")),
                TextField(controller: sleepTimeController, decoration: const InputDecoration(labelText: "Target sleep time (HH:MM)")),

                const Divider(height: 24),
                const Text("DAILY GOALS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                TextField(controller: waterController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Water target (Liters)")),
                TextField(controller: proteinController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Protein target (grams)")),
                TextField(controller: caloriesController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Calories budget (kcal)")),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                final startHr = int.tryParse(startHourController.text) ?? profile.startHour;
                
                ref.read(userProfileProvider.notifier).updateProfile(
                  name: nameController.text,
                  age: int.tryParse(ageController.text) ?? profile.age,
                  heightCm: double.tryParse(heightController.text) ?? profile.heightCm,
                  targetWeight: double.tryParse(targetController.text) ?? profile.targetWeight,
                  isMale: profile.isMale,
                  startHour: (startHr >= 0 && startHr <= 23) ? startHr : profile.startHour,
                  wakeTime: wakeTimeController.text,
                  sleepTime: sleepTimeController.text,
                  dailyWaterGoal: double.tryParse(waterController.text) ?? profile.dailyWaterGoalLiters,
                  dailyProteinGoal: double.tryParse(proteinController.text) ?? profile.dailyProteinGoalGrams,
                  dailyCaloriesGoal: double.tryParse(caloriesController.text) ?? profile.dailyCaloriesGoalKcal,
                );

                Navigator.pop(context);
              },
              child: const Text("Save Options"),
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
          title: const Text("CAUTION: HARD RESET"),
          content: const Text("This will permanently delete all weight records, food entries, completed workouts, and progress photos. You cannot undo this."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                await HiveBoxes.clearAll();
                // Close and exit dialog, tell user to restart
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("All data cleared. Please restart the application.")),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
              child: const Text("Clear Everything"),
            ),
          ],
        );
      },
    );
  }
}
