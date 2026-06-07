import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_provider.dart';
import '../../../gamification/presentation/providers/gamification_provider.dart';
import '../../../gamification/domain/user_profile.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/custom_progress.dart';
import 'main_shell.dart';
import '../providers/health_sync_provider.dart';
import '../../../ai_coach/presentation/providers/ai_coach_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final dashboard = ref.watch(dashboardProvider);
    
    // XP progress calculations
    final xpNeeded = 100 + (profile.level - 1) * 50;
    final xpPercent = (profile.xp / xpNeeded).clamp(0.0, 1.0);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (User level & XP)
              _buildHeader(context, profile, xpPercent, xpNeeded),
              const SizedBox(height: 16),

              // Watch Sync Button
              _buildWatchSyncButton(context, ref),
              const SizedBox(height: 16),

              // 2. Compliance Score Circular Ring (Game-like)
              _buildComplianceScore(context, dashboard),
              const SizedBox(height: 24),

              // 3. Weight Transformation Stats Card
              _buildWeightStats(context, profile, dashboard),
              const SizedBox(height: 20),

              // Craving Guard Panic Button
              _buildCravingGuard(context, ref),
              const SizedBox(height: 20),

              // Circadian Mission Guide
              _buildCircadianActions(context, ref, profile),
              const SizedBox(height: 20),

              // 4. Streaks & Active Cycles
              _buildStreaksSection(context, profile),
              const SizedBox(height: 20),

              // 5. Unlocked Badges (Achievements)
              _buildBadgesSection(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic profile, double xpPercent, int xpNeeded) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome back,",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            Text(
              profile.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24),
            ),
          ],
        ),
        
        // XP badge widget
        Container(
          width: 140,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.secondary.withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "LVL ${profile.level}",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 12),
                  ),
                  Text(
                    "${profile.xp}/$xpNeeded XP",
                    style: TextStyle(fontSize: 10, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: xpPercent,
                  minHeight: 6,
                  backgroundColor: AppColors.secondary.withOpacity(0.1),
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 2),
              Center(
                child: Text(
                  UserProfile.getLevelName(profile.level),
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.secondary),
                ),
              )
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildComplianceScore(BuildContext context, DashboardData dashboard) {
    final percentInt = (dashboard.complianceScore * 100).round();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Text(
            "TODAY'S COMPLIANCE SCORE",
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.primary,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          CustomProgressRing(
            progress: dashboard.complianceScore,
            size: 150,
            strokeWidth: 14,
            gradientColors: const [AppColors.primary, AppColors.green],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "$percentInt%",
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 36,
                    color: percentInt >= 80
                        ? AppColors.green
                        : percentInt >= 50
                            ? AppColors.info
                            : AppColors.orange,
                  ),
                ),
                Text(
                  percentInt >= 90
                      ? "Flawless"
                      : percentInt >= 70
                          ? "On Track"
                          : percentInt >= 50
                              ? "Average"
                              : "Keep Going",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Adherence breakdowns
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildComplianceItem(context, "Diet", dashboard.isDietAdherent ? "100%" : "${(dashboard.complianceScore * 30 / 0.3).round()}%", dashboard.isDietAdherent),
              _buildComplianceItem(context, "Workout", dashboard.isWorkoutCompleted ? "100%" : "0%", dashboard.isWorkoutCompleted),
              _buildComplianceItem(context, "Water", "${(dashboard.waterIntakePercent * 100).round()}%", dashboard.waterIntakePercent >= 1.0),
              _buildComplianceItem(context, "Habits", "${(dashboard.habitsCheckedPercent * 100).round()}%", dashboard.habitsCheckedPercent >= 0.7),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 450.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildComplianceItem(BuildContext context, String label, String value, bool isSuccess) {
    return Column(
      children: [
        Icon(
          isSuccess ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isSuccess ? AppColors.green : AppColors.orange.withOpacity(0.6),
          size: 18,
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSuccess ? AppColors.green : null)),
      ],
    );
  }

  Widget _buildWeightStats(BuildContext context, UserProfile profile, DashboardData dashboard) {
    final targetDateStr = DateFormat('MMM yyyy').format(dashboard.targetCompletionDate);
    final currentWeightPct = (dashboard.weightProgressPercent * 100).toStringAsFixed(1);
    
    return GlassCard(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("TRANSFORMATION TO 85KG", style: Theme.of(context).textTheme.titleMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "$currentWeightPct% Done",
                  style: const TextStyle(color: AppColors.green, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildWeightMetric("Current", "${profile.currentWeight.toStringAsFixed(1)} kg", AppColors.info),
              _buildWeightMetric("Goal", "${profile.targetWeight.toStringAsFixed(1)} kg", AppColors.secondary),
              _buildWeightMetric("Remaining", "${dashboard.weightRemaining.toStringAsFixed(1)} kg", AppColors.orange),
            ],
          ),
          
          const Divider(height: 24, color: AppColors.borderDark),
          
          Row(
            children: [
              const Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                "Estimated Target Completion:",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              Text(
                targetDateStr,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 450.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildWeightMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStreaksSection(BuildContext context, UserProfile profile) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildStreakCard("Overall Consistency", profile.overallStreak, Icons.local_fire_department, AppColors.orange),
          const SizedBox(width: 12),
          _buildStreakCard("Diet Streak", profile.dietStreak, Icons.restaurant, AppColors.green),
          const SizedBox(width: 12),
          _buildStreakCard("Workout Streak", profile.workoutStreak, Icons.fitness_center, AppColors.primary),
          const SizedBox(width: 12),
          _buildStreakCard("Water Streak", profile.waterStreak, Icons.water_drop, AppColors.info),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 450.ms);
  }

  Widget _buildStreakCard(String label, int streak, IconData icon, Color color) {
    return GlassCard(
      width: 150,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(
                "🔥 $streak",
                style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            streak > 0 ? "Active streak" : "No streak",
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryDark),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(badgesProvider);

    return GlassCard(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("UNLOCKED ACHIEVEMENTS", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          badgesAsync.when(
            data: (badges) {
              final unlocked = badges.where((b) => b.isUnlocked).toList();
              if (unlocked.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "No achievements unlocked yet. Complete workouts, keep streaks, and lose weight to unlock badges!",
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                  ),
                );
              }
              return SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: unlocked.length,
                  itemBuilder: (context, index) {
                    final badge = unlocked[index];
                    return Tooltip(
                      message: "${badge.title}: ${badge.description}",
                      child: Container(
                        margin: const EdgeInsets.only(right: 16),
                        child: Column(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.secondary.withOpacity(0.15),
                                border: Border.all(color: AppColors.secondary, width: 1.5),
                              ),
                              child: Text(badge.icon, style: const TextStyle(fontSize: 24)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              badge.title,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text("Error loading badges: $e"),
          )
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 450.ms);
  }

  Widget _buildCravingGuard(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      width: double.infinity,
      borderColor: AppColors.orange.withOpacity(0.5),
      backgroundColor: AppColors.orange.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield, color: AppColors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "3 AM CRAVING GUARD",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.orange,
                      fontSize: 13,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Having a midnight craving during your shift? Get instant support.",
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                ref.read(aiCoachProvider.notifier).sendMessage(
                  "I need help! I am having a massive midnight craving right now during my night shift. Help me resist it!"
                );
                ref.read(shellTabProvider.notifier).state = 4; // Navigate to AI Coach tab
              },
              child: const Text("ACTIVATE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 250.ms, duration: 450.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildWatchSyncButton(BuildContext context, WidgetRef ref) {
    final healthState = ref.watch(healthSyncProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      onTap: healthState.isSyncing ? null : () => ref.read(healthSyncProvider.notifier).syncData(),
      child: Row(
        children: [
          Icon(
            Icons.watch,
            color: healthState.error != null ? AppColors.red : AppColors.info,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "NOISEFIT WATCH SYNC",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
                Text(
                  healthState.isSyncing
                      ? "Reading from Health Connect..."
                      : healthState.error != null
                          ? healthState.error!
                          : healthState.lastSyncTime != null
                              ? "Last sync: ${healthState.lastSyncTime}"
                              : "Tap to sync steps, weight & sleep.",
                  style: TextStyle(
                    fontSize: 9,
                    color: healthState.error != null ? AppColors.red : AppColors.textSecondaryDark
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (healthState.isSyncing)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.info),
            )
          else
            const Icon(Icons.sync, size: 16, color: AppColors.info),
        ],
      ),
    );
  }

  Widget _buildCircadianActions(BuildContext context, WidgetRef ref, dynamic profile) {
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Circadian suggestions
    String title = "";
    String desc = "";
    IconData icon = Icons.wb_sunny;
    Color color = AppColors.orange;
    
    final currentHour = now.hour;
    final startHour = profile.startHour;
    
    if (currentHour >= startHour && currentHour < startHour + 2) {
      title = "MELATONIN SUPPRESSION";
      desc = "Get 10-15 minutes of bright blue-sky sunlight or high-lux lighting now to suppress melatonin and synchronize your clock.";
      icon = Icons.light_mode;
      color = AppColors.orange;
    } else if (currentHour >= 2 && currentHour < 5) {
      title = "SHIFT CRITICAL ENERGY ZONE";
      desc = "Energy levels naturally dip now. Drink cold water, stand up to walk, and ensure you have eaten protein to avoid insulin crashes.";
      icon = Icons.bolt;
      color = AppColors.secondary;
    } else if (currentHour >= 6 && currentHour < 9) {
      title = "WIND-DOWN SHIELD";
      desc = "Wear blue-blocking glasses or sunglasses on your way home. Avoid bright screens to prepare your brain for daytime sleep.";
      icon = Icons.nights_stay;
      color = AppColors.info;
    } else {
      title = "DAYTIME SLEEP QUALITY";
      desc = "Make sure your sleep environment is pitch black (use eye masks/blackouts) and kept cool (under 20°C) for deep recovery.";
      icon = Icons.bed;
      color = AppColors.green;
    }

    return GlassCard(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                "CIRCADIAN MISSION: $title",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: color,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: TextStyle(
              fontSize: 11,
              height: 1.3,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 450.ms).slideY(begin: 0.1, end: 0);
  }
}
