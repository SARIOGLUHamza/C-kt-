import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:deneme/core/constants/app_constants.dart';

// Genel yardımcı fonksiyonlar
class Helpers {
  // Dosya boyutunu formatla
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Dosya uzantısını kontrol et
  static bool isPdfFile(String filePath) {
    return filePath.toLowerCase().endsWith('.pdf');
  }

  static bool isAudioFile(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return AppConstants.supportedAudioExtensions.contains(extension);
  }

  static bool isDocumentFile(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return AppConstants.supportedDocumentExtensions.contains(extension);
  }

  // Dosya var mı kontrol et
  static Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  // Dosya boyutunu al
  static Future<int?> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      print('Dosya boyutu alınamadı: $e');
    }
    return null;
  }

  // Renk yardımcıları
  static Color getFavoriteColor(bool isFavorite) {
    return isFavorite ? Colors.amber : Colors.grey;
  }

  static IconData getFavoriteIcon(bool isFavorite) {
    return isFavorite ? Icons.star : Icons.star_border;
  }

  // Snackbar yardımcıları
  static void showSuccessSnackBar(String message, {IconData? icon}) {
    Get.snackbar(
      'Başarılı',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      duration: AppConstants.shortAnimation,
      icon: icon != null ? Icon(icon, color: Colors.green) : null,
    );
  }

  static void showErrorSnackBar(String message, {IconData? icon}) {
    Get.snackbar(
      'Hata',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      duration: AppConstants.shortAnimation,
      icon: icon != null ? Icon(icon, color: Colors.red) : null,
    );
  }

  static void showInfoSnackBar(String message, {IconData? icon, Color? color}) {
    Get.snackbar(
      'Bilgi',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: (color ?? Colors.blue).withOpacity(0.1),
      colorText: color ?? Colors.blue.shade800,
      duration: AppConstants.shortAnimation,
      icon: icon != null ? Icon(icon, color: color ?? Colors.blue) : null,
    );
  }

  // Favori mesajları
  static String getFavoriteMessage(String title, bool isFavorite) {
    return isFavorite
        ? '$title favorilere eklendi'
        : '$title favorilerden çıkarıldı';
  }

  // Tarih formatla
  static String formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }

  // ID oluştur
  static int generateId(List<int> existingIds) {
    if (existingIds.isEmpty) return 1;
    return existingIds.reduce((a, b) => a > b ? a : b) + 1;
  }
}
