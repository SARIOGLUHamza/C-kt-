import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:deneme/models/course.dart';
import 'package:deneme/models/week.dart';
import 'package:deneme/controllers/simple_controller.dart';
import 'package:deneme/database/database_helper.dart';
import 'package:deneme/views/week_detail_screen.dart';
import 'package:deneme/core/utils/helpers.dart';
import 'package:deneme/core/constants/app_constants.dart';

/// Hafta listesi ekranı - belirli bir dersin haftalarını gösterir
class WeekListScreen extends StatelessWidget {
  WeekListScreen({super.key, required this.courseId});

  final int courseId;
  final TextEditingController weekTitleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SimpleController>();
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final course = controller.courses.firstWhere((c) => c.id == courseId);
          return Text(course.name);
        }),
        backgroundColor: Color(AppConstants.primaryColorValue),
        foregroundColor: Colors.white,
      ),
      body: Obx(() => _buildWeekList()),
      floatingActionButton: _buildAddWeekButton(),
    );
  }

  /// Hafta listesini oluştur
  Widget _buildWeekList() {
    final controller = Get.find<SimpleController>();
    final course = controller.courses.firstWhere((c) => c.id == courseId);
    final weeks = course.weeks.whereType<Week>().toList();
    if (weeks.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      itemCount: weeks.length,
      itemBuilder: (context, index) {
        final week = weeks[index];
        return _buildWeekTile(week, course);
      },
    );
  }

  /// Boş durum widget'ı
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Text(
            'Henüz bölüm eklenmemiş',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            'Sağ alt köşedeki + butonuna tıklayarak bölüm ekleyebilirsiniz',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Hafta tile'ını oluştur
  Widget _buildWeekTile(Week week, Course course) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: AppConstants.smallPadding,
      ),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(AppConstants.primaryColorValue),
          child: Text(
            '${week.weekNumber}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          week.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Bölüm ${week.weekNumber}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(
              () => IconButton(
                icon: Icon(
                  Helpers.getFavoriteIcon(week.isFavorite.value),
                  color: Helpers.getFavoriteColor(week.isFavorite.value),
                ),
                onPressed: () => _toggleFavorite(week),
                tooltip:
                    week.isFavorite.value
                        ? 'Favorilerden Çıkar'
                        : 'Favorilere Ekle',
              ),
            ),
            // SEÇENEKLER BUTONU (PopupMenu)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditWeekDialog(week, course);
                } else if (value == 'delete') {
                  _showDeleteWeekDialog(week, course);
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
          ],
        ),
        onTap: () => _navigateToWeekDetail(week),
      ),
    );
  }

  /// Hafta ekleme butonu
  Widget _buildAddWeekButton() {
    return FloatingActionButton(
      onPressed: _showAddWeekDialog,
      backgroundColor: Color(AppConstants.accentColorValue),
      child: const Icon(Icons.add, color: Colors.white),
      tooltip: 'Bölüm Ekle',
    );
  }

  /// Hafta ekleme dialog'u
  void _showAddWeekDialog() {
    weekTitleController.clear();
    Get.defaultDialog(
      title: "Bölüm Başlığı Ekle",
      content: Padding(
        padding: const EdgeInsets.all(AppConstants.smallPadding),
        child: TextField(
          controller: weekTitleController,
          decoration: InputDecoration(
            hintText: AppConstants.addWeekHint,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.assignment),
          ),
          autofocus: true,
        ),
      ),
      textConfirm: "Ekle",
      textCancel: "İptal",
      confirmTextColor: Colors.white,
      cancelTextColor: Color(AppConstants.primaryColorValue),
      buttonColor: Color(AppConstants.accentColorValue),
      onConfirm: _addWeek,
    );
  }

  /// Hafta ekleme işlemi
  void _addWeek() {
    if (weekTitleController.text.trim().isNotEmpty) {
      final controller = Get.find<SimpleController>();
      final course = controller.courses.firstWhere((c) => c.id == courseId);
      final week = Week(
        title: weekTitleController.text.trim(),
        weekNumber: course.weekCount.value + 1,
      );
      Get.find<SimpleController>().weekController.addWeek(course, week);
      weekTitleController.clear();
      Get.back();
    } else {
      Helpers.showErrorSnackBar('Bölüm başlığı boş olamaz');
    }
  }

  /// Favori durumunu değiştir
  void _toggleFavorite(Week week) {
    Get.find<SimpleController>().toggleFavorite(week);
  }

  /// Hafta detay sayfasına git
  void _navigateToWeekDetail(Week week) {
    Get.to(() => WeekDetailScreen(week: week));
  }

  // HAFTA DÜZENLEME DİALOGU
  void _showEditWeekDialog(Week week, Course course) {
    weekTitleController.text = week.title;
    Get.defaultDialog(
      title: "Bölüm Başlığını Düzenle",
      content: Padding(
        padding: const EdgeInsets.all(AppConstants.smallPadding),
        child: TextField(
          controller: weekTitleController,
          decoration: const InputDecoration(
            hintText: "Yeni bölüm başlığı",
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
        if (weekTitleController.text.trim().isNotEmpty) {
          week.title = weekTitleController.text.trim();
          Get.find<SimpleController>().weekController.updateWeek(week);
          Get.find<SimpleController>().reloadData();
          Get.back();
        } else {
          Helpers.showErrorSnackBar('Bölüm başlığı boş olamaz');
        }
      },
    );
  }

  // HAFTA SİLME DİALOGU
  void _showDeleteWeekDialog(Week week, Course course) {
    Get.defaultDialog(
      title: "Bölümü Sil",
      middleText: "'${week.title}' bölümünü silmek istediğine emin misin?",
      textConfirm: "Sil",
      textCancel: "İptal",
      confirmTextColor: Colors.white,
      cancelTextColor: Color(AppConstants.primaryColorValue),
      buttonColor: Colors.red,
      onConfirm: () {
        Get.find<SimpleController>().weekController.removeWeek(course, week);
        Get.find<SimpleController>().reloadData();
        Get.back();
      },
    );
  }
}
