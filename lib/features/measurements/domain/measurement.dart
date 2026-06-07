
class BodyMeasurement {
  final String trackingDate; // "yyyy-MM-dd"
  final double weightKg;
  final double chestCm;
  final double waistCm;
  final double bicepsCm;
  final double thighsCm;
  final double neckCm;
  final double hipCm;
  final double bodyFatPercentage;

  BodyMeasurement({
    required this.trackingDate,
    required this.weightKg,
    this.chestCm = 0.0,
    this.waistCm = 0.0,
    this.bicepsCm = 0.0,
    this.thighsCm = 0.0,
    this.neckCm = 0.0,
    this.hipCm = 0.0,
    this.bodyFatPercentage = 0.0,
  });

  BodyMeasurement copyWith({
    double? weightKg,
    double? chestCm,
    double? waistCm,
    double? bicepsCm,
    double? thighsCm,
    double? neckCm,
    double? hipCm,
    double? bodyFatPercentage,
  }) {
    return BodyMeasurement(
      trackingDate: trackingDate,
      weightKg: weightKg ?? this.weightKg,
      chestCm: chestCm ?? this.chestCm,
      waistCm: waistCm ?? this.waistCm,
      bicepsCm: bicepsCm ?? this.bicepsCm,
      thighsCm: thighsCm ?? this.thighsCm,
      neckCm: neckCm ?? this.neckCm,
      hipCm: hipCm ?? this.hipCm,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trackingDate': trackingDate,
      'weightKg': weightKg,
      'chestCm': chestCm,
      'waistCm': waistCm,
      'bicepsCm': bicepsCm,
      'thighsCm': thighsCm,
      'neckCm': neckCm,
      'hipCm': hipCm,
      'bodyFatPercentage': bodyFatPercentage,
    };
  }

  factory BodyMeasurement.fromMap(Map<String, dynamic> map) {
    return BodyMeasurement(
      trackingDate: map['trackingDate'] ?? '',
      weightKg: (map['weightKg'] ?? 0.0).toDouble(),
      chestCm: (map['chestCm'] ?? 0.0).toDouble(),
      waistCm: (map['waistCm'] ?? 0.0).toDouble(),
      bicepsCm: (map['bicepsCm'] ?? 0.0).toDouble(),
      thighsCm: (map['thighsCm'] ?? 0.0).toDouble(),
      neckCm: (map['neckCm'] ?? 0.0).toDouble(),
      hipCm: (map['hipCm'] ?? 0.0).toDouble(),
      bodyFatPercentage: (map['bodyFatPercentage'] ?? 0.0).toDouble(),
    );
  }
}
