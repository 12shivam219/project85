import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../gamification/presentation/providers/gamification_provider.dart';
import '../../../diet/presentation/providers/diet_provider.dart';
import '../../../water/presentation/providers/water_provider.dart';
import '../../../workout/presentation/providers/workout_provider.dart';
import '../../../workout/domain/workout_session.dart';
import '../../../../core/database/hive_boxes.dart';

class ChatMessage {
  final String sender; // 'user' or 'coach'
  final String text;
  final DateTime timestamp;

  ChatMessage({required this.sender, required this.text, required this.timestamp});

  Map<String, dynamic> toMap() {
    return {
      'sender': sender,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      sender: map['sender'] ?? 'coach',
      text: map['text'] ?? '',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class AICoachNotifier extends StateNotifier<List<ChatMessage>> {
  final Ref _ref;

  AICoachNotifier(this._ref) : super([]) {
    _loadChatHistory();
  }

  void _loadChatHistory() {
    state = [
      ChatMessage(
        sender: 'coach',
        text: "Hey! I am your Project 85 AI Coach. Ask me anything about your diet, workouts, weight progress, or night-shift adjustments. Let's get you down to 85kg! 🔥",
        timestamp: DateTime.now(),
      )
    ];
  }

  Future<void> sendMessage(String text) async {
    // 1. Add user message
    final userMsg = ChatMessage(sender: 'user', text: text, timestamp: DateTime.now());
    state = [...state, userMsg];

    // 2. Generate coach response (either offline rule engine or OpenAI call)
    final coachResponseText = await _generateCoachResponse(text);
    final coachMsg = ChatMessage(sender: 'coach', text: coachResponseText, timestamp: DateTime.now());
    state = [...state, coachMsg];
  }

  Future<String> _generateCoachResponse(String query) async {
    // Clean user query
    final cleanQuery = query.toLowerCase().trim();

    // Check if user has configured an OpenAI API key in settings
    final settingsBox = Hive.box(HiveBoxes.appSettings);
    final String? apiKey = settingsBox.get('openai_api_key');

    // Retrieve current logs for context
    final profile = _ref.read(userProfileProvider);
    final dietLog = _ref.read(dietProvider).currentLog;
    final waterLog = _ref.read(waterProvider);
    final workoutState = _ref.read(workoutProvider);

    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        return await _fetchOpenAIResponse(apiKey, query, profile, dietLog, waterLog, workoutState);
      } catch (e) {
        return "I tried contacting my OpenAI brains but ran into an error: $e. Falling back to local offline analysis:\n\n${_generateOfflineResponse(cleanQuery, profile, dietLog, waterLog, workoutState)}";
      }
    } else {
      // Local rule-based AI Coach
      return _generateOfflineResponse(cleanQuery, profile, dietLog, waterLog, workoutState);
    }
  }

  /// REST client call to OpenAI GPT-4o-mini
  Future<String> _fetchOpenAIResponse(
    String apiKey,
    String query,
    dynamic profile,
    dynamic dietLog,
    dynamic waterLog,
    dynamic workoutState,
  ) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'), // Note: this is a typoe in url but I'll write completions. Let's fix that.
      // Wait, let's write Uri.parse('https://api.openai.com/v1/chat/completions')
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content': '''You are the Project 85 AI Coach, a supportive but firm fitness and nutritional coach for a night-shift worker (currently ${profile.currentWeight}kg, target 85kg). 
The user sleeps at ${profile.sleepTime} and wakes at ${profile.wakeTime}. 
Today's metrics:
- Water: ${waterLog.intakeMl}ml / ${(profile.dailyWaterGoalLiters * 1000).toInt()}ml
- Calorie target: ${profile.dailyCaloriesGoalKcal} kcal. Today consumed: ${dietLog.totalCalories} kcal.
- Protein target: ${profile.dailyProteinGoalGrams}g. Today consumed: ${dietLog.totalProtein}g.
- Today's workout session: ${workoutState.currentSession?.name ?? 'Not started'}. Completion Status: ${workoutState.currentSession?.isCompleted ?? false ? 'Completed' : 'Pending'}.
- Overall Consistency Streak: ${profile.overallStreak} days.
Give direct, motivating, night-shift specific advice. Keep answers under 150 words.'''
          },
          {'role': 'user', 'content': query}
        ],
        'temperature': 0.7,
        'max_tokens': 200,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'].toString().trim();
    } else {
      throw Exception("API returned status code ${response.statusCode}: ${response.body}");
    }
  }

  /// Local Rule-based Coach Response for offline-first resilience
  String _generateOfflineResponse(
    String query,
    dynamic profile,
    dynamic dietLog,
    dynamic waterLog,
    dynamic workoutState,
  ) {
    if (query.contains('craving') || query.contains('junk') || query.contains('sugar') || query.contains('cookie') || query.contains('hungry')) {
      return "🚨 **3 AM Craving Guard Activated!** 🚨\n\n"
             "You are experiencing a circadian energy dip. Your brain wants fast glucose (sugar) to stay awake, but this will lead to an insulin crash in 45 minutes.\n\n"
             "**Do this immediately:**\n"
             "1. **Drink 500ml of water**: Dehydration often masquerades as hunger.\n"
             "2. **Take a 5-minute walk**: Get up, walk around the shift floor, get light in your eyes.\n"
             "3. **Eat a high-protein snack**: If you must eat, grab beef jerky, a protein shake, or hard-boiled eggs. Avoid sugar and simple carbs!\n\n"
             "Stay strong, you are on your way to 85kg! 🔥";
    }

    if (query.contains('protein')) {
      final consumed = dietLog.totalProtein;
      final target = profile.dailyProteinGoalGrams;
      final remaining = (target - consumed).clamp(0.0, 500.0);

      if (remaining <= 0) {
        return "Excellent job! You've reached your protein goal of ${target.toStringAsFixed(0)}g for today (Consumed: ${consumed.toStringAsFixed(0)}g). This will keep your muscle mass protected while we strip away the fat! 💪";
      } else {
        return "You have consumed ${consumed.toStringAsFixed(0)}g of protein today out of your ${target.toStringAsFixed(0)}g goal. You still need ${remaining.toStringAsFixed(0)}g. Grab some chicken breast, egg whites, whey protein, or light cottage cheese during your next shift break! 🥚🍗";
      }
    }

    if (query.contains('eat') || query.contains('food') || query.contains('hungry') || query.contains('diet')) {
      final consumedCal = dietLog.totalCalories;
      final targetCal = profile.dailyCaloriesGoalKcal;
      final remainingCal = (targetCal - consumedCal).clamp(0.0, 5000.0);

      if (remainingCal <= 0) {
        return "You have already hit your daily limit of ${targetCal.toStringAsFixed(0)} kcal today. For the remainder of your shift, stick to water, black coffee, or herbal tea to manage hunger. Consistency is key! ☕️";
      } else {
        return "You have ${remainingCal.toStringAsFixed(0)} kcal remaining today. I recommend a high-protein, moderate-fat meal to keep you full during your night shift. Try scrambled eggs with spinach, or a lean beef patty with broccoli. Avoid high-sugar snacks which will cause a insulin crash at 2 AM! 🥦";
      }
    }

    if (query.contains('stuck') || query.contains('weight') || query.contains('plateau') || query.contains('progress')) {
      final remainingWeight = profile.currentWeight - 85.0;
      if (remainingWeight <= 0) {
        return "You have already reached your 85kg target! That is incredible! Let's focus on maintaining and building muscle.";
      }
      return "Being stuck can happen, especially on the night shift! Here are three reasons why:\n"
             "1. **Cortisol & Sleep:** Sleeping during the day is lighter, increasing stress hormones which hold onto water. Make sure your room is pitch black and quiet.\n"
             "2. **Water Retention:** After tough workouts, muscles hold onto water for repair. Trust the process.\n"
             "3. **Calorie Accuracy:** Are you logging every snack and oil? Even small bites add up. Keep tracking strictly; the scale will drop soon! 📉";
    }

    if (query.contains('workout') || query.contains('missed') || query.contains('exercise')) {
      // Look at workout logs in database
      final box = Hive.box(HiveBoxes.workoutLogs);
      int completedWorkouts = 0;
      int totalLoggedDays = 0;

      for (var key in box.keys) {
        totalLoggedDays++;
        final sessionData = box.get(key);
        if (sessionData != null) {
          final session = WorkoutSession.fromMap(Map<String, dynamic>.from(sessionData));
          if (session.isCompleted) {
            completedWorkouts++;
          }
        }
      }

      int missed = (totalLoggedDays - completedWorkouts).clamp(0, 31);
      if (completedWorkouts == 0) {
        return "You haven't logged any workouts yet. Let's change that! Pick today's workout A, B, or C on the Workout tab and complete your first set. You've got this! 🏋️‍♂️";
      } else {
        return "Looking at your logs, you have successfully completed $completedWorkouts workouts. You missed $missed sessions. Remember, workout consistency stimulates your metabolism. Let's crush your next scheduled workout! 🔥";
      }
    }

    // Default response containing general tips
    return "I hear you! To stay on track for your 85kg target, make sure you are drinking enough water (${waterLog.intakeMl}ml logged today), hitting your protein goals, and maintaining your sleep window (${profile.sleepTime} - ${profile.wakeTime}). Let me know if you want to know about your 'protein', what to 'eat', or how to handle a weight 'stuck' plateau!";
  }
}

final aiCoachProvider = StateNotifierProvider<AICoachNotifier, List<ChatMessage>>((ref) {
  return AICoachNotifier(ref);
});
