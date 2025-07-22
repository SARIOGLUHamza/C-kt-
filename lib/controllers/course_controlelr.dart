import 'package:deneme/models/course.dart';
import 'package:deneme/models/week.dart';
import 'package:deneme/core/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:deneme/database/database_helper.dart';
import 'package:deneme/controllers/simple_controller.dart';
import 'package:deneme/database/CourseDao.dart';

class CourseController extends GetxController {
  final CourseDao _courseDao = CourseDao();
  final RxList<Course> courses = <Course>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadData();
  }

  Future<void> _loadData() async {
    final fetchedCourses = await _courseDao.getAllCourses();
    courses.assignAll(fetchedCourses);
    courses.refresh();
  }

  /// Yeni ders ekle
  Future<void> addCourse(String name, {String? description}) async {
    try {
      print('Ders ekleme başlatıldı: $name');

      // Önce veritabanına kaydet ve ID'yi al
      final tempCourse = Course(
        id: 0, // Geçici ID
        name: name,
        description: description,
        weeks: <Week>[].obs,
        favoriteCount: 0.obs,
        weekCount: 0.obs,
      );

      final courseId = await _courseDao.insertCourse(tempCourse);

      // Gerçek ID ile Course oluştur
      final course = Course(
        id: courseId,
        name: name,
        description: description,
        weeks: <Week>[].obs,
        favoriteCount: 0.obs,
        weekCount: 0.obs,
      );

      // Mevcut listeye ekle (tüm veriyi yeniden yükleme)
      courses.add(course);
      courses.refresh();

      // EKRANI GÜNCELLE
      await Get.find<SimpleController>().reloadData();

      print('Ders başarıyla eklendi: ${course.name}');
      Helpers.showSuccessSnackBar('$name dersi eklendi', icon: Icons.add);
    } catch (e) {
      print('Ders eklenirken hata oluştu: $e');
      Helpers.showErrorSnackBar('Ders eklenirken hata oluştu');
    }
  }

  /// Ders güncelle
  Future<void> updateCourse(Course course) async {
    try {
      await _courseDao.updateCourse(course);

      // Sadece courses listesini refresh et (_loadData() kullanma)
      courses.refresh();

      print('Ders başarıyla güncellendi: ${course.name}');
      Helpers.showSuccessSnackBar('${course.name} dersi güncellendi');
    } catch (e) {
      print('Ders güncellenirken hata oluştu: $e');
      Helpers.showErrorSnackBar('Ders güncellenirken hata oluştu');
    }
  }

  /// Ders sil
  Future<void> removeCourse(Course course) async {
    try {
      if (course.id != null) {
        await _courseDao.deleteCourse(course.id!);

        // Mevcut listeden sil (tüm veriyi yeniden yükleme)
        courses.remove(course);
        courses.refresh();

        print('Ders başarıyla silindi: ${course.name}');
        Helpers.showSuccessSnackBar(
          '${course.name} dersi silindi',
          icon: Icons.delete,
        );
      }
    } catch (e) {
      print('Ders silinirken hata oluştu: $e');
      Helpers.showErrorSnackBar('Ders silinirken hata oluştu');
    }
  }
}
