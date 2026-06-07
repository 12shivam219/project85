import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/progress_photo.dart';
import '../../../../core/database/hive_boxes.dart';

class PhotoNotifier extends StateNotifier<List<ProgressPhotoEntry>> {
  PhotoNotifier() : super([]) {
    _loadPhotos();
  }

  void _loadPhotos() {
    final box = Hive.box(HiveBoxes.progressPhotos);
    final List<ProgressPhotoEntry> list = [];
    
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        final map = Map<String, dynamic>.from(data);
        list.add(ProgressPhotoEntry.fromMap(map));
      }
    }
    
    // Sort by date descending
    list.sort((a, b) => b.trackingDate.compareTo(a.trackingDate));
    state = list;
  }

  Future<void> addPhoto(String trackingDate, String type, String path) async {
    final box = Hive.box(HiveBoxes.progressPhotos);
    final existingData = box.get(trackingDate);
    
    ProgressPhotoEntry entry;
    if (existingData != null) {
      final existingEntry = ProgressPhotoEntry.fromMap(Map<String, dynamic>.from(existingData));
      entry = existingEntry.copyWith(
        frontPath: type == 'front' ? path : null,
        sidePath: type == 'side' ? path : null,
        backPath: type == 'back' ? path : null,
      );
    } else {
      entry = ProgressPhotoEntry(
        trackingDate: trackingDate,
        frontPath: type == 'front' ? path : null,
        sidePath: type == 'side' ? path : null,
        backPath: type == 'back' ? path : null,
      );
    }

    await box.put(trackingDate, entry.toMap());
    _loadPhotos();
  }

  Future<void> deletePhotoEntry(String trackingDate) async {
    final box = Hive.box(HiveBoxes.progressPhotos);
    await box.delete(trackingDate);
    _loadPhotos();
  }
}

final photoProvider = StateNotifierProvider<PhotoNotifier, List<ProgressPhotoEntry>>((ref) {
  return PhotoNotifier();
});
