import 'package:flutter/material.dart';
import '../../domain/exercise.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/widgets/glass_card.dart';

class ExerciseDbScreen extends StatefulWidget {
  const ExerciseDbScreen({super.key});

  @override
  State<ExerciseDbScreen> createState() => _ExerciseDbScreenState();
}

class _ExerciseDbScreenState extends State<ExerciseDbScreen> {
  final List<Exercise> _allExercises = Exercise.getInitialDatabase();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // Categories list
    final categories = ['All', ..._allExercises.map((e) => e.category).toSet().toList()];

    // Filtered exercises
    final filtered = _allExercises.where((e) {
      final matchesCat = _selectedCategory == 'All' || e.category == _selectedCategory;
      final matchesSearch = e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.instructions.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Exercise Library", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            // Search field
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search exercises...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: AppColors.cardDark.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 12),

            // Categories list chips
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(cat),
                      onSelected: (val) {
                        setState(() => _selectedCategory = cat);
                      },
                      selectedColor: AppColors.primary.withOpacity(0.25),
                      checkmarkColor: AppColors.primary,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Exercises List
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text("No exercises found.", style: TextStyle(color: AppColors.textSecondaryDark)))
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final ex = filtered[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            child: Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                leading: Text(ex.animation, style: const TextStyle(fontSize: 24)),
                                title: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(ex.category, style: const TextStyle(color: AppColors.primary, fontSize: 11)),
                                childrenPadding: const EdgeInsets.all(8.0),
                                children: [
                                  Row(
                                    children: ex.targetMuscles.map((m) => Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      child: Chip(
                                        label: Text(m, style: const TextStyle(fontSize: 10)),
                                        backgroundColor: AppColors.cardDark,
                                      ),
                                    )).toList(),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Instructions:",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ex.instructions,
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
