import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:deneme/models/week.dart';
import 'package:deneme/models/course.dart';
import 'package:deneme/controllers/simple_controller.dart';
import 'package:deneme/views/week_detail_screen.dart';
import 'package:deneme/core/utils/helpers.dart';
import 'package:deneme/core/constants/app_constants.dart';

/// Favori haftalar ekranı - favori olarak işaretlenen haftaları gösterir
class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Obx(() => _buildFavoriteList()));
  }

  /// Favori listesini oluştur
  Widget _buildFavoriteList() {
    final controller = Get.find<SimpleController>();
    final favoriteWeeks = controller.favoriteWeeks;

    if (favoriteWeeks.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: favoriteWeeks.length,
      itemBuilder: (context, index) {
        final week = favoriteWeeks[index];
        return _buildFavoriteWeekTile(week, controller);
      },
    );
  }

  /// Boş durum widget'ı
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: AppConstants.defaultPadding),
          Text(
            AppConstants.noFavoritesMessage,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            'Bölümleri favorilere eklemek için yıldız ikonuna tıklayın',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Favori hafta tile'ını oluştur
  Widget _buildFavoriteWeekTile(Week week, SimpleController controller) {
    // Haftanın ait olduğu dersi bul
    final course = controller.courses.firstWhere(
      (c) => c.id == week.courseId,
      orElse: () => Course(id: -1, name: week.title, weeks: <Week>[].obs),
    );

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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ders: ${course.name}'),
            Text('Bölüm ${week.weekNumber}'),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            Helpers.getFavoriteIcon(week.isFavorite.value),
            color: Helpers.getFavoriteColor(week.isFavorite.value),
          ),
          onPressed: () => controller.toggleFavorite(week),
          tooltip:
              week.isFavorite.value ? 'Favorilerden Çıkar' : 'Favorilere Ekle',
        ),
        onTap: () => _navigateToWeekDetail(week),
      ),
    );
  }

  /// Hafta detay sayfasına git
  void _navigateToWeekDetail(Week week) {
    Get.to(() => WeekDetailScreen(week: week));
  }
}
