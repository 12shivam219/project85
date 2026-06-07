import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../measurements/presentation/providers/measurement_provider.dart';
import '../../../measurements/domain/measurement.dart';
import '../../../photos/presentation/providers/photo_provider.dart';
import '../../../photos/domain/progress_photo.dart';
import '../../../gamification/presentation/providers/gamification_provider.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/utils/night_shift_helper.dart';
import '../../../../core/utils/calculators.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final measurements = ref.watch(measurementProvider);
    final photoLogs = ref.watch(photoProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("ANALYTICS & STATS", style: Theme.of(context).textTheme.displayMedium),
                  ElevatedButton.icon(
                    onPressed: () => _showAddMeasurementDialog(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text("Log Stats", style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondaryDark,
                tabs: const [
                  Tab(text: "Charts & Metrics"),
                  Tab(text: "Progress Photos"),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMetricsTab(context, measurements),
                    _buildPhotosTab(context, photoLogs),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= METRICS TAB =================
  Widget _buildMetricsTab(BuildContext context, List<BodyMeasurement> measurements) {
    if (measurements.isEmpty) {
      return const Center(
        child: Text(
          "No measurements logged yet.\nTap 'Log Stats' at the top to begin tracking!",
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondaryDark),
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        // Weight Trend Chart
        Text("Weight Loss Trend (kg)", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: _buildWeightChart(measurements),
        ),
        const SizedBox(height: 24),

        // List of history entries
        Text("History Logs", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: measurements.length,
          itemBuilder: (context, index) {
            final m = measurements[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.trackingDate,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Waist: ${m.waistCm}cm | Chest: ${m.chestCm}cm${m.hipCm > 0 ? ' | Hips: ${m.hipCm}cm' : ''} | BF: ${m.bodyFatPercentage.toStringAsFixed(1)}%",
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          "${m.weightKg.toStringAsFixed(1)} kg",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.green),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.red, size: 20),
                          onPressed: () => ref.read(measurementProvider.notifier).deleteMeasurement(m.trackingDate),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildWeightChart(List<BodyMeasurement> measurements) {
    // Reverse array to show chronological order
    final reversed = measurements.reversed.toList();
    List<FlSpot> spots = [];
    for (int i = 0; i < reversed.length; i++) {
      spots.add(FlSpot(i.toDouble(), reversed[i].weightKg));
    }

    // Calculate dynamic range for Y axis
    double minW = 1000;
    double maxW = 0;
    for (var m in reversed) {
      if (m.weightKg < minW) minW = m.weightKg;
      if (m.weightKg > maxW) maxW = m.weightKg;
    }
    // Include 85kg in range if close
    if (minW > 85) minW = 84;

    // Add padding to range
    minW = (minW - 5).clamp(0, 500);
    maxW = (maxW + 5).clamp(0, 500);

    return LineChart(
      LineChartData(
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 85,
              color: AppColors.orange.withOpacity(0.6),
              strokeWidth: 2,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 10, bottom: 5),
                style: const TextStyle(color: AppColors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                labelResolver: (line) => "GOAL: 85kg",
              ),
            ),
          ],
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => const FlLine(color: AppColors.borderDark, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                int index = val.toInt();
                if (index >= 0 && index < reversed.length && (index % (reversed.length > 5 ? reversed.length ~/ 3 : 1) == 0)) {
                  // Format to short date
                  final date = DateTime.parse(reversed[index].trackingDate);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MM/dd').format(date),
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryDark),
                    ),
                  );
                }
                return const Text("");
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (val, meta) {
                return Text(
                  "${val.toInt()}kg",
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryDark),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: minW,
        maxY: maxW,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.green]),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.2), AppColors.green.withOpacity(0.01)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= PHOTOS TAB =================
  Widget _buildPhotosTab(BuildContext context, List<ProgressPhotoEntry> entries) {
    final profile = ref.watch(userProfileProvider);
    final trackingDay = NightShiftHelper.getTrackingDay(DateTime.now(), startHour: profile.startHour);
    final dateStr = DateFormat('yyyy-MM-dd').format(trackingDay);

    // Get today's photo entry if exists
    final todayEntry = entries.firstWhere(
      (e) => e.trackingDate == dateStr,
      orElse: () => ProgressPhotoEntry(trackingDate: dateStr),
    );

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        // 1. Add Today's Photos
        Text("Today's Progress Photos", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildPhotoPickerItem("Front", todayEntry.frontPath, 'front', dateStr),
            _buildPhotoPickerItem("Side", todayEntry.sidePath, 'side', dateStr),
            _buildPhotoPickerItem("Back", todayEntry.backPath, 'back', dateStr),
          ],
        ),
        const SizedBox(height: 24),

        // 2. Before & After Slider Comparison
        if (entries.length >= 2) ...[
          Text("Before vs After Slider", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text("Drag handle to compare visual improvements.", style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
          const SizedBox(height: 12),
          _buildBeforeAfterSlider(entries),
          const SizedBox(height: 24),
        ],

        // 3. Photo Gallery Timeline
        Text("Visual Photo Timeline", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        entries.isEmpty
            ? const Center(child: Text("No photos uploaded yet.", style: TextStyle(color: AppColors.textSecondaryDark)))
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.75,
                ),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  // Show the front photo if available, else first non-null
                  final path = entry.frontPath ?? entry.sidePath ?? entry.backPath;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: AppColors.cardDark,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (path != null)
                            Image.file(File(path), fit: BoxFit.cover)
                          else
                            const Icon(Icons.photo, color: AppColors.textSecondaryDark),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              color: Colors.black.withOpacity(0.6),
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              child: Text(
                                entry.trackingDate,
                                style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildPhotoPickerItem(String label, String? path, String type, String dateStr) {
    return GestureDetector(
      onTap: () => _pickImage(type, dateStr),
      child: GlassCard(
        width: 105,
        height: 140,
        padding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (path != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(File(path), fit: BoxFit.cover),
              )
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo, size: 28, color: AppColors.primary),
                  const SizedBox(height: 8),
                  Text("Add $label", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            if (path != null)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                  child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(String type, String dateStr) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      ref.read(photoProvider.notifier).addPhoto(dateStr, type, image.path);
    }
  }

  Widget _buildBeforeAfterSlider(List<ProgressPhotoEntry> entries) {
    // Take the oldest entry and the newest entry
    final oldest = entries.last;
    final newest = entries.first;

    final beforeImg = oldest.frontPath ?? oldest.sidePath ?? oldest.backPath;
    final afterImg = newest.frontPath ?? newest.sidePath ?? newest.backPath;

    if (beforeImg == null || afterImg == null) {
      return const GlassCard(
        width: double.infinity,
        height: 100,
        child: Center(
          child: Text(
            "Upload photos on different days to enable before/after slider.",
            style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
          ),
        ),
      );
    }

    return BeforeAfterImageSlider(
      beforeImage: beforeImg,
      afterImage: afterImg,
      beforeLabel: "Before (${oldest.trackingDate})",
      afterLabel: "After (${newest.trackingDate})",
    );
  }

  // ================= DIALOGS =================
  void _showAddMeasurementDialog(BuildContext context) {
    final weightController = TextEditingController();
    final waistController = TextEditingController();
    final chestController = TextEditingController();
    final bicepsController = TextEditingController();
    final thighsController = TextEditingController();
    final neckController = TextEditingController();
    final hipController = TextEditingController();

    final profile = ref.read(userProfileProvider);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Log Body Measurements"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Weight (kg)*", hintText: "E.g., 108.0"),
                ),
                TextField(
                  controller: waistController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Waist (cm)", hintText: "E.g., 110"),
                ),
                TextField(
                  controller: chestController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Chest (cm)", hintText: "E.g., 115"),
                ),
                TextField(
                  controller: bicepsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Biceps (cm)"),
                ),
                TextField(
                  controller: thighsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Thighs (cm)"),
                ),
                TextField(
                  controller: neckController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Neck (cm)", hintText: "E.g., 42"),
                ),
                if (!profile.isMale)
                  TextField(
                    controller: hipController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Hips (cm)*", hintText: "Required for female BF%"),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final double weight = double.tryParse(weightController.text) ?? 0.0;
                if (weight <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Weight is required!")),
                  );
                  return;
                }

                final double waist = double.tryParse(waistController.text) ?? 0.0;
                final double chest = double.tryParse(chestController.text) ?? 0.0;
                final double biceps = double.tryParse(bicepsController.text) ?? 0.0;
                final double thighs = double.tryParse(thighsController.text) ?? 0.0;
                final double neck = double.tryParse(neckController.text) ?? 0.0;
                final double hips = double.tryParse(hipController.text) ?? 0.0;

                final profile = ref.read(userProfileProvider);
                final trackingDay = NightShiftHelper.getTrackingDay(DateTime.now(), startHour: profile.startHour);
                final dateStr = DateFormat('yyyy-MM-dd').format(trackingDay);

                // Estimate body fat
                double bf = 0.0;
                bool canCalcBF = profile.isMale ? (waist > 0 && neck > 0) : (waist > 0 && neck > 0 && hips > 0);

                if (canCalcBF) {
                  bf = HealthCalculators.estimateBodyFat(
                    waist,
                    neck,
                    profile.heightCm,
                    profile.isMale,
                    hipCm: hips,
                  );
                }

                final entry = BodyMeasurement(
                  trackingDate: dateStr,
                  weightKg: weight,
                  chestCm: chest,
                  waistCm: waist,
                  bicepsCm: biceps,
                  thighsCm: thighs,
                  neckCm: neck,
                  hipCm: hips,
                  bodyFatPercentage: bf,
                );

                ref.read(measurementProvider.notifier).addMeasurement(entry);
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}

// ================= CUSTOM BEFORE/AFTER IMAGE SLIDER WIDGET =================
class BeforeAfterImageSlider extends StatefulWidget {
  final String beforeImage;
  final String afterImage;
  final String beforeLabel;
  final String afterLabel;

  const BeforeAfterImageSlider({
    super.key,
    required this.beforeImage,
    required this.afterImage,
    required this.beforeLabel,
    required this.afterLabel,
  });

  @override
  State<BeforeAfterImageSlider> createState() => _BeforeAfterImageSliderState();
}

class _BeforeAfterImageSliderState extends State<BeforeAfterImageSlider> {
  double _sliderPosition = 0.5; // 0.0 to 1.0

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            return GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _sliderPosition = (_sliderPosition + details.delta.dx / width).clamp(0.0, 1.0);
                });
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. After Image (Bottom Layer)
                  Image.file(
                    File(widget.afterImage),
                    width: width,
                    height: height,
                    fit: BoxFit.cover,
                  ),
                  
                  // Label for After Image
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: Colors.black54,
                      child: Text(widget.afterLabel, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  // 2. Before Image (Top Layer, Clipped)
                  ClipRect(
                    clipper: _SliderClipper(_sliderPosition),
                    child: Image.file(
                      File(widget.beforeImage),
                      width: width,
                      height: height,
                      fit: BoxFit.cover,
                    ),
                  ),

                  // Label for Before Image
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: Colors.black54,
                      child: Text(widget.beforeLabel, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  // 3. Slider Handle Divider
                  Positioned(
                    left: width * _sliderPosition - 1,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2.5,
                      color: AppColors.primary,
                    ),
                  ),
                  
                  // Handle Thumb circle
                  Positioned(
                    left: width * _sliderPosition - 16,
                    top: height / 2 - 16,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(Icons.unfold_more, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SliderClipper extends CustomClipper<Rect> {
  final double fraction;
  _SliderClipper(this.fraction);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0.0, 0.0, size.width * fraction, size.height);
  }

  @override
  bool shouldReclip(_SliderClipper oldClipper) {
    return oldClipper.fraction != fraction;
  }
}
