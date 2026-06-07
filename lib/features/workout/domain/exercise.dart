class Exercise {
  final String id;
  final String name;
  final String category; // E.g., "Legs", "Back", "Shoulders", "Chest", "Band", "HIIT"
  final String instructions;
  final List<String> targetMuscles;
  final String animation; // Local icon/illustration indicator
  final String notes;

  Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.instructions,
    required this.targetMuscles,
    required this.animation,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'instructions': instructions,
      'targetMuscles': targetMuscles,
      'animation': animation,
      'notes': notes,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      instructions: map['instructions'] ?? '',
      targetMuscles: List<String>.from(map['targetMuscles'] ?? []),
      animation: map['animation'] ?? '',
      notes: map['notes'] ?? '',
    );
  }

  static List<Exercise> getInitialDatabase() {
    return [
      Exercise(
        id: 'goblet_squat',
        name: 'Goblet Squat',
        category: 'Legs',
        instructions: 'Hold a dumbbell or kettlebell close to your chest. Keep your chest up, squat down until thighs are parallel to ground, then press through your heels to return to standing.',
        targetMuscles: ['Quads', 'Glutes', 'Core'],
        animation: '🏋️‍♂️',
        notes: 'Great for night shift workers with limited equipment. Keep spine neutral.',
      ),
      Exercise(
        id: 'romanian_deadlift',
        name: 'Romanian Deadlift',
        category: 'Legs / Posterior',
        instructions: 'Hold weights in front of thighs. Hinge at hips, push glutes back, lower weights down shins while keeping back flat. Squeeze glutes to stand.',
        targetMuscles: ['Hamstrings', 'Glutes', 'Lower Back'],
        animation: '🍑',
        notes: 'Control the descent. Focus on hamstring stretch.',
      ),
      Exercise(
        id: 'walking_lunge',
        name: 'Walking Lunge',
        category: 'Legs',
        instructions: 'Take a step forward, lowering hips until both knees are bent at 90-degree angles. Step forward with the trailing leg to repeat.',
        targetMuscles: ['Quads', 'Glutes', 'Hamstrings'],
        animation: '🏃‍♂️',
        notes: 'Keep knee in line with foot. Do not let knee cave in.',
      ),
      Exercise(
        id: 'deadlift',
        name: 'Deadlift',
        category: 'Full Body',
        instructions: 'Stand with feet mid-foot under barbell/dumbbells. Hinge and bend knees, grip weights. Lift by pushing feet into floor, keeping back flat. Lock out at top.',
        targetMuscles: ['Posterior Chain', 'Hamstrings', 'Glutes', 'Back', 'Core'],
        animation: '🏋️‍♀️',
        notes: 'Primary builder for strength. Do not round your lower back.',
      ),
      Exercise(
        id: 'glute_bridge',
        name: 'Glute Bridge',
        category: 'Posterior',
        instructions: 'Lie on back with knees bent, feet flat on floor. Drive heels down, raise hips by squeezing glutes until body forms a straight line knee-to-shoulders.',
        targetMuscles: ['Glutes', 'Hamstrings', 'Core'],
        animation: '🌉',
        notes: 'Add weight on hips to increase difficulty.',
      ),
      Exercise(
        id: 'bent_over_row',
        name: 'Bent Over Row',
        category: 'Back',
        instructions: 'Hinge at hips with weights in hand, back flat. Pull elbows back, squeezing shoulder blades together, then lower weights with control.',
        targetMuscles: ['Lats', 'Upper Back', 'Biceps'],
        animation: '🚣‍♂️',
        notes: 'Pull towards your belly button, not your chest.',
      ),
      Exercise(
        id: 'shoulder_press',
        name: 'Shoulder Press',
        category: 'Shoulders',
        instructions: 'Sit or stand holding weights at shoulder level. Press weights straight overhead until arms are locked, then lower back slowly to shoulders.',
        targetMuscles: ['Deltoids', 'Triceps', 'Upper Chest'],
        animation: '💪',
        notes: 'Keep core engaged to avoid arching back.',
      ),
      Exercise(
        id: 'chest_fly',
        name: 'Chest Fly',
        category: 'Chest',
        instructions: 'Lie on bench or floor holding weights above chest. Lower weights in wide arc outwards until stretch is felt in chest, then reverse arc to starting position.',
        targetMuscles: ['Pectorals', 'Front Delts'],
        animation: '🦅',
        notes: 'Keep a slight bend in the elbows throughout.',
      ),
      Exercise(
        id: 'band_lat_pulldown',
        name: 'Resistance Band Lat Pulldown',
        category: 'Band',
        instructions: 'Anchor band overhead. Grip handles, sit or kneel, pull handles down and outwards towards chest, squeezing lats. Control band return.',
        targetMuscles: ['Lats', 'Shoulders', 'Biceps'],
        animation: '🎗️',
        notes: 'Excellent joint-friendly option for home workouts.',
      ),
      Exercise(
        id: 'hiit_burpees',
        name: 'HIIT Burpees',
        category: 'HIIT',
        instructions: 'Drop into squat, jump feet back into push-up position, complete push-up, jump feet forward to hands, explode up in vertical jump.',
        targetMuscles: ['Cardio', 'Full Body', 'Quads', 'Chest'],
        animation: '🔥',
        notes: 'Maximum intensity. Great for burning calories at the end of the shift.',
      ),
    ];
  }
}
