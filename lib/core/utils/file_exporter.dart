import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../features/measurements/domain/measurement.dart';
import '../../features/diet/domain/meal.dart';
import '../../features/workout/domain/workout_session.dart';

class FileExporter {
  /// Export data to CSV and Share
  static Future<void> exportToCSV({
    required List<BodyMeasurement> measurements,
    required List<DailyDietLog> dietLogs,
    required List<WorkoutSession> workouts,
  }) async {
    List<List<dynamic>> rows = [];
    
    // Title Section
    rows.add(["PROJECT 85 - TRANSFORMATION REPORT (CSV)"]);
    rows.add([]);

    // 1. Weight & Measurements
    rows.add(["WEIGHT & MEASUREMENTS HISTORY"]);
    rows.add(["Date", "Weight (kg)", "Waist (cm)", "Chest (cm)", "Biceps (cm)", "Thighs (cm)", "Neck (cm)", "Body Fat (%)"]);
    for (var m in measurements) {
      rows.add([
        m.trackingDate,
        m.weightKg,
        m.waistCm,
        m.chestCm,
        m.bicepsCm,
        m.thighsCm,
        m.neckCm,
        m.bodyFatPercentage,
      ]);
    }
    rows.add([]);

    // 2. Diet Logs
    rows.add(["DIET LOGS HISTORY"]);
    rows.add(["Date", "Meal Name", "Calories (kcal)", "Protein (g)", "Carbs (g)", "Fat (g)", "Status", "Notes"]);
    for (var log in dietLogs) {
      for (var meal in log.meals) {
        rows.add([
          log.trackingDate,
          meal.name,
          meal.calories,
          meal.protein,
          meal.carbs,
          meal.fat,
          meal.isCompleted ? "Completed" : "Pending",
          meal.notes,
        ]);
      }
    }
    rows.add([]);

    // 3. Workouts Logs
    rows.add(["WORKOUT LOGS HISTORY"]);
    rows.add(["Date", "Workout Type", "Exercise Name", "Set Number", "Weight (kg)", "Reps", "Status"]);
    for (var w in workouts) {
      for (var ex in w.exercises) {
        for (var set in ex.sets) {
          rows.add([
            w.trackingDate,
            w.name,
            ex.exerciseName,
            set.setNumber,
            set.weightKg,
            set.reps,
            set.isCompleted ? "Completed" : "Missed",
          ]);
        }
      }
    }

    String csvContent = const ListToCsvConverter().convert(rows);

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/Project_85_Transformation_Report.csv');
    await file.writeAsString(csvContent);

    // Share File
    await Share.shareXFiles([XFile(file.path)], text: 'My Project 85 CSV Transformation Report');
  }

  /// Export data to Excel Sheet and Share
  static Future<void> exportToExcel({
    required List<BodyMeasurement> measurements,
    required List<DailyDietLog> dietLogs,
    required List<WorkoutSession> workouts,
  }) async {
    var excel = Excel.createExcel();
    
    // Rename default sheet
    String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, 'Measurements');

    // 1. Sheet - Weight & Measurements
    Sheet measSheet = excel['Measurements'];
    measSheet.appendRow([
      TextCellValue("Date"), 
      TextCellValue("Weight (kg)"), 
      TextCellValue("Waist (cm)"), 
      TextCellValue("Chest (cm)"), 
      TextCellValue("Biceps (cm)"), 
      TextCellValue("Thighs (cm)"), 
      TextCellValue("Neck (cm)"), 
      TextCellValue("Body Fat (%)")
    ]);
    for (var m in measurements) {
      measSheet.appendRow([
        TextCellValue(m.trackingDate),
        DoubleCellValue(m.weightKg),
        DoubleCellValue(m.waistCm),
        DoubleCellValue(m.chestCm),
        DoubleCellValue(m.bicepsCm),
        DoubleCellValue(m.thighsCm),
        DoubleCellValue(m.neckCm),
        DoubleCellValue(m.bodyFatPercentage),
      ]);
    }

    // 2. Sheet - Diet
    Sheet dietSheet = excel['Diet Logs'];
    dietSheet.appendRow([
      TextCellValue("Date"), 
      TextCellValue("Meal Name"), 
      TextCellValue("Calories (kcal)"), 
      TextCellValue("Protein (g)"), 
      TextCellValue("Carbs (g)"), 
      TextCellValue("Fat (g)"), 
      TextCellValue("Status"), 
      TextCellValue("Notes")
    ]);
    for (var log in dietLogs) {
      for (var meal in log.meals) {
        dietSheet.appendRow([
          TextCellValue(log.trackingDate),
          TextCellValue(meal.name),
          DoubleCellValue(meal.calories),
          DoubleCellValue(meal.protein),
          DoubleCellValue(meal.carbs),
          DoubleCellValue(meal.fat),
          TextCellValue(meal.isCompleted ? "Completed" : "Pending"),
          TextCellValue(meal.notes),
        ]);
      }
    }

    // 3. Sheet - Workouts
    Sheet workoutSheet = excel['Workout Logs'];
    workoutSheet.appendRow([
      TextCellValue("Date"), 
      TextCellValue("Workout Name"), 
      TextCellValue("Exercise Name"), 
      TextCellValue("Set"), 
      TextCellValue("Weight (kg)"), 
      TextCellValue("Reps"), 
      TextCellValue("Completed")
    ]);
    for (var w in workouts) {
      for (var ex in w.exercises) {
        for (var set in ex.sets) {
          workoutSheet.appendRow([
            TextCellValue(w.trackingDate),
            TextCellValue(w.name),
            TextCellValue(ex.exerciseName),
            IntCellValue(set.setNumber),
            DoubleCellValue(set.weightKg),
            IntCellValue(set.reps),
            TextCellValue(set.isCompleted ? "Yes" : "No"),
          ]);
        }
      }
    }

    final directory = await getTemporaryDirectory();
    final fileBytes = excel.save();
    
    if (fileBytes != null) {
      final file = File('${directory.path}/Project_85_Transformation_Report.xlsx');
      await file.writeAsBytes(fileBytes);

      // Share File
      await Share.shareXFiles([XFile(file.path)], text: 'My Project 85 Excel Transformation Report');
    }
  }

  /// Export data to Premium PDF Report and Share
  static Future<void> exportToPDF({
    required List<BodyMeasurement> measurements,
    required List<DailyDietLog> dietLogs,
    required List<WorkoutSession> workouts,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("PROJECT 85 - PROGRESS REPORT", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Transformation to 85kg", style: const pw.TextStyle(color: PdfColors.blueGrey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Weight section
            pw.Text("1. Weight & Body Measurements Trends", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ["Date", "Weight (kg)", "Waist (cm)", "Chest (cm)", "Biceps (cm)", "Body Fat %"],
              data: measurements.take(15).map((m) => [
                m.trackingDate,
                m.weightKg.toStringAsFixed(1),
                m.waistCm.toStringAsFixed(1),
                m.chestCm.toStringAsFixed(1),
                m.bicepsCm.toStringAsFixed(1),
                m.bodyFatPercentage.toStringAsFixed(1),
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              cellHeight: 20,
            ),
            pw.SizedBox(height: 20),

            // Workout summary
            pw.Text("2. Workout Completion History", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ["Date", "Workout Type", "Exercises Completed", "Status"],
              data: workouts.take(15).map((w) {
                final completedCount = w.exercises.where((e) => e.isCompleted).length;
                return [
                  w.trackingDate,
                  w.name,
                  "$completedCount / ${w.exercises.length}",
                  w.isCompleted ? "COMPLETED" : "INCOMPLETE"
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.purple800),
              cellHeight: 20,
            ),
            pw.SizedBox(height: 20),

            // Diet Summary
            pw.Text("3. Diet Adherence Log", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ["Date", "Meals Complete", "Avg Calories Consumed", "Status"],
              data: dietLogs.take(15).map((d) {
                final completedCount = d.meals.where((m) => m.isCompleted).length;
                final status = d.complianceRate >= 1.0 ? "ADHERENT" : "PARTIAL";
                return [
                  d.trackingDate,
                  "$completedCount / ${d.meals.length}",
                  "${d.totalCalories.toStringAsFixed(0)} kcal",
                  status,
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
              cellHeight: 20,
            ),
          ];
        },
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/Project_85_Transformation_Report.pdf');
    await file.writeAsBytes(await pdf.save());

    // Share File
    await Share.shareXFiles([XFile(file.path)], text: 'My Project 85 PDF Transformation Report');
  }
}
