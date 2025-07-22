import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:deneme/controllers/simple_controller.dart';
import 'package:deneme/views/week_list_screen.dart';
import 'package:deneme/core/utils/helpers.dart';
import 'package:deneme/core/constants/app_constants.dart';
import 'package:deneme/models/week.dart';
import 'package:deneme/database/database_helper.dart';

/// Ders listesi ekranı - tüm dersleri gösterir
class CourseListScreen extends StatelessWidget {
  CourseListScreen({super.key});

  final TextEditingController courseNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => _buildCourseList()),
      floatingActionButton: _buildAddCourseButton(),
    );
  }

  /// Ders listesini oluştur
  Widget _buildCourseList() {
    final controller = Get.find<SimpleController>();

    if (controller.courses.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: controller.courses.length,
      itemBuilder: (context, index) {
        final course = controller.courses[index];
        return _buildCourseTile(course);
      },
    );
  }

  /// Boş durum widget'ı
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: AppConstants.defaultPadding),
          Text(
            'Henüz ders eklenmemiş',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            'Sağ alt köşedeki + butonuna tıklayarak ders ekleyebilirsiniz',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Ders tile'ını oluştur
  Widget _buildCourseTile(dynamic course) {
    // Favori hafta sayısını güvenli bir şekilde hesapla

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: AppConstants.smallPadding,
      ),
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(AppConstants.primaryColorValue),
          child: const Icon(Icons.school, color: Colors.white),
        ),
        title: Text(
          course.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Obx(
          () => Text(
            '${course.weekCount.value} Bölüm',
            style: TextStyle(
              color: course.weeks.isEmpty ? Colors.grey : Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (course.weeks.isNotEmpty)
              Obx(
                () => Text(
                  ' ${course.favoriteCount.value}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
              ),
            const Icon(Icons.favorite, color: Colors.amber, size: 16),
            const SizedBox(width: 8),
            // SEÇENEKLER BUTONU (PopupMenu)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditCourseDialog(course);
                } else if (value == 'delete') {
                  _showDeleteCourseDialog(course);
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit, color: Colors.blue),
                        title: Text('Düzenle'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Sil'),
                      ),
                    ),
                  ],
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: () => _navigateToWeekList(course),
      ),
    );
  }

  /// Ders ekleme butonu
  Widget _buildAddCourseButton() {
    return FloatingActionButton(
      onPressed: _showAddCourseDialog,
      backgroundColor: Color(AppConstants.accentColorValue),
      child: const Icon(Icons.add, color: Colors.white),
      tooltip: 'Ders Ekle',
    );
  }

  /// Ders ekleme dialog'u
  void _showAddCourseDialog() {
    courseNameController.clear();

    Get.defaultDialog(
      title: "Yeni Ders Ekle",
      content: Padding(
        padding: const EdgeInsets.all(AppConstants.smallPadding),
        child: TextField(
          controller: courseNameController,
          decoration: InputDecoration(
            hintText: AppConstants.addCourseHint,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.school),
          ),
          autofocus: true,
        ),
      ),
      textConfirm: "Ekle",
      textCancel: "İptal",
      confirmTextColor: Colors.white,
      cancelTextColor: Color(AppConstants.primaryColorValue),
      buttonColor: Color(AppConstants.primaryColorValue),
      onConfirm: _addCourse,
    );
  }

  /// Ders ekleme işlemi
  void _addCourse() {
    if (courseNameController.text.trim().isNotEmpty) {
      Get.find<SimpleController>().courseController.addCourse(
        courseNameController.text.trim(),
      );
      courseNameController.clear();
      Get.back();
    } else {
      Helpers.showErrorSnackBar('Ders adı boş olamaz');
    }
  }

  // DERS DÜZENLEME DİALOGU
  void _showEditCourseDialog(dynamic course) {
    courseNameController.text = course.name;
    Get.defaultDialog(
      title: "Ders Adını Düzenle",
      content: Padding(
        padding: const EdgeInsets.all(AppConstants.smallPadding),
        child: TextField(
          controller: courseNameController,
          decoration: const InputDecoration(
            hintText: "Yeni ders adı",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.edit),
          ),
          autofocus: true,
        ),
      ),
      textConfirm: "Kaydet",
      textCancel: "İptal",
      confirmTextColor: Colors.white,
      cancelTextColor: Color(AppConstants.primaryColorValue),
      buttonColor: Color(AppConstants.primaryColorValue),
      onConfirm: () {
        if (courseNameController.text.trim().isNotEmpty) {
          course.name = courseNameController.text.trim();
          Get.find<SimpleController>().courseController.updateCourse(course);
          Get.find<SimpleController>().reloadData();
          Get.back();
        } else {
          Helpers.showErrorSnackBar('Ders adı boş olamaz');
        }
      },
    );
  }

  // DERS SİLME DİALOGU
  void _showDeleteCourseDialog(dynamic course) {
    Get.defaultDialog(
      title: "Dersi Sil",
      middleText: "'${course.name}' dersini silmek istediğine emin misin?",
      textConfirm: "Sil",
      textCancel: "İptal",
      confirmTextColor: Colors.white,
      cancelTextColor: Color(AppConstants.primaryColorValue),
      buttonColor: Colors.red,
      onConfirm: () {
        Get.find<SimpleController>().courseController.removeCourse(course);
        Get.find<SimpleController>().reloadData();
        Get.back();
      },
    );
  }

  /// Hafta listesi sayfasına git
  void _navigateToWeekList(dynamic course) {
    Get.to(() => WeekListScreen(courseId: course.id));
  }
}
