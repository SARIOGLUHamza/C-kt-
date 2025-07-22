import 'package:deneme/models/course.dart';
import 'package:deneme/models/week.dart';
import 'package:deneme/core/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:deneme/database/database_helper.dart';
import 'package:deneme/controllers/course_controlelr.dart';
import 'package:deneme/database/weekDao.dart';
import 'package:deneme/database/meiafileDao.dart';
import 'dart:io';
import 'dart:convert';

class WeekController extends GetxController {
  final WeekDao _weekDao = WeekDao();
  final MediaFileDao _mediaFileDao = MediaFileDao();
  final RxList<Week> weeks = <Week>[].obs;
  final CourseController courseController = Get.find();

  @override
  void onInit() {
    super.onInit();
  }

  /// Yeni hafta ekle
  Future<void> addWeek(Course course, Week week) async {
    try {
      print('Hafta ekleme başlatıldı: ${week.title}');

      // CourseId'yi set et
      week.courseId = course.id;

      // Veritabanına kaydet
      final weekId = await _weekDao.insertWeek(week);

      // Week'e yeni ID'yi ata
      week.id = weekId;

      // Sadece o dersin haftalarını güncelle (tüm veriyi yeniden yükleme)
      if (course.id != null) {
        final updatedWeeks = await _weekDao.getWeeksByCourse(course.id!);

        // RxList'i doğru şekilde güncelle (Obx için daha güvenilir)
        course.weeks.clear();
        course.weeks.addAll(updatedWeeks);
        course.weekCount.value++; // Sadece eklemede artır

        // Global courses listesini de güncelle
        courseController.courses.refresh();
      }

      print('Hafta başarıyla eklendi: ${week.title}');
      Helpers.showSuccessSnackBar(
        '${week.title} haftası eklendi',
        icon: Icons.add,
      );
    } catch (e) {
      print('Hafta eklenirken hata oluştu: $e');
      Helpers.showErrorSnackBar('Hafta eklenirken hata oluştu');
    }
  }

  /// Hafta güncelle
  Future<void> updateWeek(Week week) async {
    try {
      await _weekDao.updateWeek(week);

      // Sadece courses listesini refresh et (_loadData() kullanma)

      print('Hafta başarıyla güncellendi: ${week.title}');
      Helpers.showSuccessSnackBar('${week.title} haftası güncellendi');
    } catch (e) {
      print('Hafta güncellenirken hata oluştu: $e');
      Helpers.showErrorSnackBar('Hafta güncellenirken hata oluştu');
    }

    courseController.courses.refresh();
  }

  /// Hafta içeriğini güncelle
  Future<void> updateWeekContent(Week week, String content) async {
    try {
      week.content = content;
      if (week.id != null) {
        await _weekDao.updateWeek(week);
      }
    } catch (e) {
      print('Week content güncellenirken hata: $e');
    }
  }

  /// Hafta sil
  Future<void> removeWeek(Course course, Week week) async {
    try {
      if (week.id != null) {
        await _weekDao.deleteWeek(week.id!);

        // Sadece o dersin haftalarını güncelle
        if (course.id != null) {
          final updatedWeeks = await _weekDao.getWeeksByCourse(course.id!);

          // RxList'i doğru şekilde güncelle (Obx için daha güvenilir)
          course.weeks.clear();
          course.weeks.addAll(updatedWeeks);
          if (course.weekCount.value > 0)
            course.weekCount.value--; // Sadece silmede azalt

          courseController.courses.refresh();
        }

        print('Hafta başarıyla silindi: ${week.title}');
        Helpers.showSuccessSnackBar(
          '${week.title} haftası silindi',
          icon: Icons.delete,
        );
      }
    } catch (e) {
      print('Hafta silinirken hata oluştu: $e');
      Helpers.showErrorSnackBar('Hafta silinirken hata oluştu');
    }
  }

  Future<void> deleteMediaFile(MediaFile media, Week week) async {
    // 1. Dosya cihazda varsa sil
    final file = File(media.filePath);
    if (await file.exists()) {
      await file.delete();
    }

    // 2. Quill embed'i sil (eğer context ve WeekDetailScreen varsa)
    final context = Get.context;
    if (context != null) {
      final state = context.findAncestorStateOfType<State<StatefulWidget>>();
      try {
        (state as dynamic)?._removeFileEmbedFromQuill(media.filePath);
      } catch (_) {}
    }

    // 3. Veritabanından sil
    await _mediaFileDao.deleteMediaFile(media.id!);

    // 4. Listeden çıkar
    week.mediaFiles.remove(media);
    week.mediaFiles.refresh();
  }

  Future<void> safeDeleteMediaFile(MediaFile media, Week week) async {
    if (media.filePath.isEmpty || media.fileName.isEmpty) {
      Get.snackbar('Hata', 'Geçersiz dosya bilgisi');
      return;
    }
    // Embed’i önce temizle
    final context = Get.context;
    if (context != null) {
      final screenState =
          context.findAncestorStateOfType<State<StatefulWidget>>();
      try {
        (screenState as dynamic)?._removeFileEmbedFromQuill(media.filePath);
      } catch (_) {}
    }
    await deleteMediaFile(media, week);
  }
}
