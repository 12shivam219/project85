import 'user_profile.dart';

class BadgeModel {
  final String id;
  final String title;
  final String description;
  final String icon; // Icon name/string E.g., 'fitness_center', 'calendar_today', etc.
  final bool isUnlocked;
  final String? unlockedDate;

  BadgeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
    this.unlockedDate,
  });

  BadgeModel copyWith({
    bool? isUnlocked,
    String? unlockedDate,
  }) {
    return BadgeModel(
      id: id,
      title: title,
      description: description,
      icon: icon,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedDate: unlockedDate ?? this.unlockedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'isUnlocked': isUnlocked,
      'unlockedDate': unlockedDate,
    };
  }

  factory BadgeModel.fromMap(Map<String, dynamic> map) {
    return BadgeModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '',
      isUnlocked: map['isUnlocked'] ?? false,
      unlockedDate: map['unlockedDate'],
    );
  }

  static List<BadgeModel> getInitialBadges() {
    return [
      BadgeModel(
        id: 'first_workout',
        title: 'First Blood',
        description: 'Complete your first workout session.',
        icon: '🔥',
      ),
      BadgeModel(
        id: 'streak_7',
        title: '7 Day Warrior',
        description: 'Maintain a 7-day adherence streak.',
        icon: '⚔️',
      ),
      BadgeModel(
        id: 'streak_30',
        title: 'Unstoppable Force',
        description: 'Maintain a 30-day adherence streak.',
        icon: '🛡️',
      ),
      BadgeModel(
        id: 'lost_5',
        title: 'Lightening Up',
        description: 'Lose your first 5 kg.',
        icon: '⚡',
      ),
      BadgeModel(
        id: 'lost_10',
        title: 'Heavy Duty',
        description: 'Lose 10 kg of body weight.',
        icon: '💪',
      ),
      BadgeModel(
        id: 'lost_15',
        title: 'New Man',
        description: 'Lose 15 kg of body weight.',
        icon: '🦅',
      ),
      BadgeModel(
        id: 'goal_achieved',
        title: 'Project 85 Master',
        description: 'Transform down to your target 85 kg weight!',
        icon: '👑',
      ),
    ];
  }

  /// Automatically checks and unlocks badges based on user state
  static List<BadgeModel> evaluateBadges(UserProfile profile, List<BadgeModel> currentBadges, int totalWorkouts) {
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    
    return currentBadges.map((badge) {
      if (badge.isUnlocked) return badge;

      bool shouldUnlock = false;
      switch (badge.id) {
        case 'first_workout':
          shouldUnlock = totalWorkouts >= 1;
          break;
        case 'streak_7':
          shouldUnlock = profile.overallStreak >= 7;
          break;
        case 'streak_30':
          shouldUnlock = profile.overallStreak >= 30;
          break;
        case 'lost_5':
          shouldUnlock = (profile.startWeight - profile.currentWeight) >= 5.0;
          break;
        case 'lost_10':
          shouldUnlock = (profile.startWeight - profile.currentWeight) >= 10.0;
          break;
        case 'lost_15':
          shouldUnlock = (profile.startWeight - profile.currentWeight) >= 15.0;
          break;
        case 'goal_achieved':
          shouldUnlock = profile.currentWeight <= 85.0;
          break;
      }

      if (shouldUnlock) {
        return badge.copyWith(
          isUnlocked: true,
          unlockedDate: todayStr,
        );
      }
      return badge;
    }).toList();
  }
}
