import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:deneme/models/course.dart';
import 'package:deneme/models/week.dart';
import 'package:deneme/models/note.dart';
import 'package:deneme/database/database_helper.dart';
import 'package:deneme/core/utils/helpers.dart';
import 'package:deneme/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:deneme/controllers/course_controlelr.dart';
import 'package:deneme/controllers/week_controler.dart';
import 'package:deneme/controllers/note_controller.dart';
import 'package:deneme/database/CourseDao.dart';
import 'package:deneme/database/weekDao.dart';
import 'package:deneme/database/noteDao.dart';

/// Ana uygulama controller'ı - dersler, haftalar ve notları yönetir
class SimpleController extends GetxController {
  final CourseController courseController = Get.find();
  final WeekController weekController = Get.find();
  final NoteController noteController = Get.find();

  // Observable veriler
  var courses = <Course>[].obs;

  // DAO instances
  final CourseDao _courseDao = CourseDao();
  final WeekDao _weekDao = WeekDao();
  final NoteDao _noteDao = NoteDao();

  @override
  void onInit() {
    super.onInit();
    _loadData();
    // cleanupOnStartup(); // Başlangıçta eski dosyaları temizle
    print('SimpleController başlatıldı');
  }

  /// Gömülmüş PDF listesini getir (SharedPreferences üzerinden)
  Future<List<String>> getEmbeddedPdfsList() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('embedded_pdfs') ?? [];
  }

  /// PDF dosya adından timestamp çıkar
  int _extractTimestamp(String pdfPath) {
    try {
      final regex = RegExp(r'_annotated_(\d+)\.pdf');
      final match = regex.firstMatch(pdfPath);
      if (match != null) {
        return int.parse(match.group(1)!);
      }
    } catch (e) {
      print("Timestamp çıkarılamadı: $e");
    }
    return 0;
  }

  // Tüm haftalara kolay erişim için getter
  List<Week> get weeks =>
      courses.expand((course) => course.weeks.whereType<Week>()).toList();
  List<Week> get favoriteWeeks =>
      courses
          .expand((course) => course.weeks.whereType<Week>())
          .where((week) => week.isFavorite.value)
          .toList();

  /// Uygulama başlangıcında verileri yükle
  Future<void> _loadData() async {
    try {
      print('Veriler veritabanından yükleniyor...');

      // Dersleri yükle
      final loadedCourses = await _courseDao.getAllCourses();
      print("deneme");
      courses.value = loadedCourses;

      // Her dersin haftalarını yükle
      for (var course in courses) {
        if (course.id != null) {
          final weeks = await _weekDao.getWeeksByCourse(course.id!);
          course.weeks.value = weeks;
          course.weekCount.value = weeks.length; // Haftaların sayısını güncelle
          final favCount = await _weekDao.getFavoriteWeekCountByCourse(
            course.id!,
          );
          course.favoriteCount.value = favCount;
        }
      }
      courses.refresh();

      print('Veriler yüklendi: ${courses.length} ders');
    } catch (e) {
      print('Veriler yüklenirken hata: $e');
      courses.value = [];
    }
  }

  /// Favori durumunu değiştir
  Future<void> toggleFavorite(Week week) async {
    week.isFavorite.value = !week.isFavorite.value;
    await _weekDao.updateWeek(week);

    final course = courses.firstWhereOrNull((c) => c.id == week.courseId);
    if (course != null) {
      // Favori sayısını veritabanından çekip güncelle
      if (week.isFavorite.value) {
        course.favoriteCount.value++;
      } else {
        course.favoriteCount.value--;
      }
      await _courseDao.updateCourse(course);
    }
    courses.refresh();
  }

  /// Belirli dersin haftalarını getir
  Future<List<Week>> getWeeksByCourse(int courseId) async {
    try {
      return await _weekDao.getWeeksByCourse(courseId);
    } catch (e) {
      print('Haftalar alınırken hata: $e');
      return [];
    }
  }

  /// Debug ve yeniden yükleme fonksiyonları

  /// Debug için veritabanı durumunu yazdır
  Future<void> debugPrintDatabase() async {
    try {
      print('=== VERİTABANI DEBUG ===');

      final allCourses = await _courseDao.getAllCourses();
      print('Toplam kurs sayısı: ${allCourses.length}');

      for (var course in allCourses) {
        print('Ders: ${course.name} (ID: ${course.id})');

        if (course.id != null) {
          final weeks = await _weekDao.getWeeksByCourse(course.id!);
          print('  - Hafta sayısı: ${weeks.length}');

          for (var week in weeks) {
            print(
              '    * Hafta: ${week.title} (ID: ${week.id}, Favori: ${week.isFavorite})',
            );

            if (week.id != null) {
              final notes = await _noteDao.getNotesByWeek(week.id!);
              print('      - Not sayısı: ${notes.length}');
            }
          }
        }
      }
      print('========================');
    } catch (e) {
      print('Debug hata: $e');
    }
  }

  // ================================
  // GÖMÜLMÜŞ PDF TAKİP SİSTEMİ
  // ================================

  /// En son gömülmüş PDF yolunu kaydet
  Future<void> saveLastEmbeddedPdf(String pdfPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_embedded_pdf', pdfPath);

      // Gömülmüş PDF'ler listesini güncelle
      List<String> embeddedPdfs = await getEmbeddedPdfsList();
      if (!embeddedPdfs.contains(pdfPath)) {
        embeddedPdfs.add(pdfPath);
        await prefs.setStringList('embedded_pdfs', embeddedPdfs);
      }

      print("✅ En son gömülmüş PDF kaydedildi: $pdfPath");
    } catch (e) {
      print("❌ En son gömülmüş PDF kaydedilirken hata: $e");
    }
  }

  /// En son gömülmüş PDF yolunu al
  Future<String?> getLastEmbeddedPdf() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastPdf = prefs.getString('last_embedded_pdf');

      // Dosyanın hala var olup olmadığını kontrol et
      if (lastPdf != null && await File(lastPdf).exists()) {
        return lastPdf;
      }
      return null;
    } catch (e) {
      print("❌ En son gömülmüş PDF alınırken hata: $e");
      return null;
    }
  }

  /// Orijinal PDF için en son gömülmüş versiyonunu al
  Future<String?> getLatestEmbeddedVersion(String originalPdfPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final embeddedPdfs = prefs.getStringList('embedded_pdfs') ?? [];

      final baseName = originalPdfPath.split('/').last.split('.').first;

      // Bu PDF için gömülmüş versiyonları bul
      final relatedPdfs =
          embeddedPdfs
              .where(
                (pdf) => pdf.contains(baseName) && pdf.contains('_annotated_'),
              )
              .toList();

      if (relatedPdfs.isEmpty) return null;

      // En son oluşturulanı bul (timestamp'e göre)
      relatedPdfs.sort((a, b) {
        final timestampA = _extractTimestamp(a);
        final timestampB = _extractTimestamp(b);
        return timestampB.compareTo(timestampA);
      });

      final latestPdf = relatedPdfs.first;

      // Dosyanın hala var olup olmadığını kontrol et
      if (await File(latestPdf).exists()) {
        return latestPdf;
      } else {
        // Artık yoksa listeden çıkar
        embeddedPdfs.remove(latestPdf);
        await prefs.setStringList('embedded_pdfs', embeddedPdfs);
        return null;
      }
    } catch (e) {
      print("❌ En son gömülmüş versiyon alınırken hata: $e");
      return null;
    }
  }

  /// Eski gömülmüş PDF'leri temizle (bellek optimizasyonu)
  Future<void> cleanOldEmbeddedPdfs(String currentPdfPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final embeddedPdfs = prefs.getStringList('embedded_pdfs') ?? [];

      final baseName = currentPdfPath.split('/').last.split('.').first;

      // Bu PDF için eski versiyonları bul
      final oldVersions =
          embeddedPdfs
              .where(
                (pdf) =>
                    pdf.contains(baseName) &&
                    pdf.contains('_annotated_') &&
                    pdf != currentPdfPath,
              )
              .toList();

      int deletedCount = 0;
      for (final oldPdf in oldVersions) {
        try {
          final file = File(oldPdf);
          if (await file.exists()) {
            await file.delete();
            deletedCount++;
          }
          embeddedPdfs.remove(oldPdf);
        } catch (e) {
          print("Eski PDF silinemedi: $oldPdf - $e");
        }
      }

      // Güncellenmiş listeyi kaydet
      await prefs.setStringList('embedded_pdfs', embeddedPdfs);

      if (deletedCount > 0) {
        print('🗑️ $deletedCount eski gömülmüş PDF temizlendi');
      }
    } catch (e) {
      print("❌ Eski PDF'ler temizlenirken hata: $e");
    }
  }

  /// PDF annotation'larını temizle (gömme sonrası)
  Future<void> clearPdfAnnotations(String pdfPath) async {
    try {
      final fileName = pdfPath.split('/').last;

      // Çizim ve not dosyalarını sil
      final directory = await getApplicationDocumentsDirectory();

      final drawingsFile = File('${directory.path}/drawings_$fileName.json');
      final notesFile = File('${directory.path}/notes_$fileName.json');

      if (await drawingsFile.exists()) {
        await drawingsFile.delete();
        print('🧹 Çizim dosyası temizlendi: $fileName');
      }

      if (await notesFile.exists()) {
        await notesFile.delete();
        print('🧹 Not dosyası temizlendi: $fileName');
      }
    } catch (e) {
      print("❌ PDF annotation'ları temizlenirken hata: $e");
    }
  }

  /// Yeni hafta ekle
  Future<void> addWeek(
    int courseId,
    String title, {
    String? description,
    int? weekNumber,
  }) async {
    try {
      final week = Week(
        courseId: courseId,
        title: title,
        description: description,
        weekNumber: weekNumber ?? 1,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      final id = await _weekDao.insertWeek(week);
      week.id = id;
      // İlgili course'u bul ve haftayı ekle
      final course = courses.firstWhereOrNull((c) => c.id == courseId);
      if (course != null) {
        course.weeks.add(week);
        course.weeks.refresh();
      }
      courses.refresh();
    } catch (e) {
      print('Hafta eklenirken hata: $e');
    }
  }

  /// EKRANI GÜNCELLEMEK İÇİN GLOBAL FONKSİYON
  Future<void> reloadData() async {
    print('Veriler yeniden yükleniyor...');
    await _loadData();
  }
}
