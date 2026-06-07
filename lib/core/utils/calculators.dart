import 'dart:math' as math;

class HealthCalculators {
  /// Calculate Body Mass Index (BMI)
  static double calculateBMI(double weightKg, double heightCm) {
    if (heightCm <= 0) return 0.0;
    final double heightM = heightCm / 100.0;
    return weightKg / (heightM * heightM);
  }

  /// Categorize BMI
  static String getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal Weight';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  /// Calculate Basal Metabolic Rate (BMR) using Mifflin-St Jeor Equation
  static double calculateBMR(double weightKg, double heightCm, int age, bool isMale) {
    if (isMale) {
      return (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * age) + 5.0;
    } else {
      return (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * age) - 161.0;
    }
  }

  /// Calculate Total Daily Energy Expenditure (TDEE) based on activity level
  /// activityLevel:
  /// 1.2: Sedentary (office job, little/no exercise)
  /// 1.375: Lightly active (light exercise 1-3 days/week)
  /// 1.55: Moderately active (moderate exercise 3-5 days/week)
  /// 1.725: Very active (hard exercise 6-7 days/week)
  /// 1.9: Extra active (very hard exercise, physical job)
  static double calculateTDEE(double bmr, double activityMultiplier) {
    return bmr * activityMultiplier;
  }

  /// Estimate Body Fat percentage using the U.S. Navy Circumference Method
  /// Neck and Waist should be in cm. Height in cm.
  static double estimateBodyFat(double waistCm, double neckCm, double heightCm, bool isMale, {double hipCm = 0}) {
    if (waistCm <= neckCm || heightCm <= 0) return 0.0;
    
    // Natural log is log() in Dart. Base 10 log is log(x) / log(10)
    double log10(double value) => math.log(value) / math.ln10;

    if (isMale) {
      final double denominator = 1.0324 - (0.19077 * log10(waistCm - neckCm)) + (0.15456 * log10(heightCm));
      if (denominator <= 0) return 0.0;
      final double bf = (495.0 / denominator) - 450.0;
      return bf.clamp(2.0, 60.0);
    } else {
      final double waistHipNeck = waistCm + hipCm - neckCm;
      if (waistHipNeck <= 0) return 0.0;
      final double denominator = 1.29579 - (0.35004 * log10(waistHipNeck)) + (0.22100 * log10(heightCm));
      if (denominator <= 0) return 0.0;
      final double bf = (495.0 / denominator) - 450.0;
      return bf.clamp(2.0, 60.0);
    }
  }

  /// Estimate daily protein requirement in grams.
  /// For active fat loss, protein targets range from 1.6 to 2.2g per kg.
  /// We default to 2.0g per kg of bodyweight.
  static double calculateDailyProteinGoal(double weightKg) {
    return weightKg * 2.0;
  }
}
