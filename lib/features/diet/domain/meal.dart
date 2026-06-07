
class MealItem {
  final String id;
  final String name;
  final String scheduledTime; // e.g. "18:00" (6 PM)
  final bool isCompleted;
  final bool xpAwarded;
  final String? completionTime; // e.g. "18:15"
  final String notes;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  MealItem({
    required this.id,
    required this.name,
    required this.scheduledTime,
    this.isCompleted = false,
    this.xpAwarded = false,
    this.completionTime,
    this.notes = '',
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  MealItem copyWith({
    bool? isCompleted,
    bool? xpAwarded,
    String? completionTime,
    String? notes,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
  }) {
    return MealItem(
      id: id,
      name: name,
      scheduledTime: scheduledTime,
      isCompleted: isCompleted ?? this.isCompleted,
      xpAwarded: xpAwarded ?? this.xpAwarded,
      completionTime: completionTime ?? this.completionTime,
      notes: notes ?? this.notes,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'scheduledTime': scheduledTime,
      'isCompleted': isCompleted,
      'xpAwarded': xpAwarded,
      'completionTime': completionTime,
      'notes': notes,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  factory MealItem.fromMap(Map<String, dynamic> map) {
    return MealItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      scheduledTime: map['scheduledTime'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      xpAwarded: map['xpAwarded'] ?? false,
      completionTime: map['completionTime'],
      notes: map['notes'] ?? '',
      calories: (map['calories'] ?? 0.0).toDouble(),
      protein: (map['protein'] ?? 0.0).toDouble(),
      carbs: (map['carbs'] ?? 0.0).toDouble(),
      fat: (map['fat'] ?? 0.0).toDouble(),
    );
  }
}

class DailyDietLog {
  final String trackingDate; // "yyyy-MM-dd"
  final List<MealItem> meals;

  DailyDietLog({
    required this.trackingDate,
    required this.meals,
  });

  double get totalCalories => meals.where((m) => m.isCompleted).fold(0, (prev, m) => prev + m.calories);
  double get totalProtein => meals.where((m) => m.isCompleted).fold(0, (prev, m) => prev + m.protein);
  double get totalCarbs => meals.where((m) => m.isCompleted).fold(0, (prev, m) => prev + m.carbs);
  double get totalFat => meals.where((m) => m.isCompleted).fold(0, (prev, m) => prev + m.fat);

  double get complianceRate {
    if (meals.isEmpty) return 0.0;
    final completedCount = meals.where((m) => m.isCompleted).length;
    return completedCount / meals.length;
  }

  Map<String, dynamic> toMap() {
    return {
      'trackingDate': trackingDate,
      'meals': meals.map((m) => m.toMap()).toList(),
    };
  }

  factory DailyDietLog.fromMap(Map<String, dynamic> map) {
    return DailyDietLog(
      trackingDate: map['trackingDate'] ?? '',
      meals: List<MealItem>.from((map['meals'] ?? []).map((x) => MealItem.fromMap(x))),
    );
  }

  static DailyDietLog createDefault(String trackingDate, {int startHour = 17}) {
    // Schedule shifted to start at 5 PM (17:00)
    // Wake: 5 PM. Sleep: 4 AM.
    // Meal 1: 6 PM (18:00)
    // Snack 1: 8:30 PM (20:30)
    // Meal 2: 11 PM (23:00)
    // Snack 2: 1:30 AM (01:30)
    // Meal 3: 3 AM (03:00)
    return DailyDietLog(
      trackingDate: trackingDate,
      meals: [
        MealItem(
          id: 'meal_1',
          name: 'Meal 1 (High Protein Wakeup)',
          scheduledTime: '18:00',
          calories: 550,
          protein: 45,
          carbs: 40,
          fat: 15,
        ),
        MealItem(
          id: 'snack_1',
          name: 'Snack 1 (Pre-Workout Fuel)',
          scheduledTime: '20:30',
          calories: 250,
          protein: 20,
          carbs: 25,
          fat: 8,
        ),
        MealItem(
          id: 'meal_2',
          name: 'Meal 2 (Night-Shift Dinner)',
          scheduledTime: '23:00',
          calories: 650,
          protein: 50,
          carbs: 45,
          fat: 18,
        ),
        MealItem(
          id: 'snack_2',
          name: 'Snack 2 (Midnight Power Snack)',
          scheduledTime: '01:30',
          calories: 200,
          protein: 15,
          carbs: 15,
          fat: 5,
        ),
        MealItem(
          id: 'meal_3',
          name: 'Meal 3 (Post-Shift Sleep Prep)',
          scheduledTime: '03:00',
          calories: 550,
          protein: 40,
          carbs: 35,
          fat: 15,
        ),
      ],
    );
  }
}
