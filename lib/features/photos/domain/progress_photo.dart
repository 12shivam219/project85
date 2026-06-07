
class ProgressPhotoEntry {
  final String trackingDate; // "yyyy-MM-dd"
  final String? frontPath;
  final String? sidePath;
  final String? backPath;

  ProgressPhotoEntry({
    required this.trackingDate,
    this.frontPath,
    this.sidePath,
    this.backPath,
  });

  bool get hasAnyPhoto => frontPath != null || sidePath != null || backPath != null;

  ProgressPhotoEntry copyWith({
    String? frontPath,
    String? sidePath,
    String? backPath,
  }) {
    return ProgressPhotoEntry(
      trackingDate: trackingDate,
      frontPath: frontPath ?? this.frontPath,
      sidePath: sidePath ?? this.sidePath,
      backPath: backPath ?? this.backPath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trackingDate': trackingDate,
      'frontPath': frontPath,
      'sidePath': sidePath,
      'backPath': backPath,
    };
  }

  factory ProgressPhotoEntry.fromMap(Map<String, dynamic> map) {
    return ProgressPhotoEntry(
      trackingDate: map['trackingDate'] ?? '',
      frontPath: map['frontPath'],
      sidePath: map['sidePath'],
      backPath: map['backPath'],
    );
  }
}
