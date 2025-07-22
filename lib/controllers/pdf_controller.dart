import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:deneme/controllers/simple_controller.dart';

class PdfController extends GetxController {
  // PDF çizim verilerini kaydetme
  Future<void> savePdfDrawing(
    String pdfPath,
    List<Map<String, dynamic>> drawingPoints,
    List<Map<String, dynamic>> notes,
  ) async {
    try {
      final String key = _getStorageKey(pdfPath);
      final Map<String, dynamic> data = {
        'pdf_key': key,
        'pdf_path': pdfPath,
        'drawing_points': drawingPoints,
        'notes': notes,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Basit dosya tabanlı storage
      await _saveToFile(key, data);
      print('PDF çizim verileri kaydedildi: $pdfPath');
    } catch (e) {
      print('PDF çizim verileri kaydedilirken hata: $e');
    }
  }

  // PDF çizim verilerini yükleme
  Future<Map<String, dynamic>?> loadPdfDrawing(String pdfPath) async {
    try {
      final String key = _getStorageKey(pdfPath);
      final data = await _loadFromFile(key);

      if (data != null) {
        return {
          'drawingPoints': data['drawing_points'] ?? [],
          'notes': data['notes'] ?? [],
          'timestamp': data['timestamp'],
        };
      }
      return null;
    } catch (e) {
      print('PDF çizim verileri yüklenirken hata: $e');
      return null;
    }
  }

  // PDF için tüm kayıtlı verileri silme
  Future<void> clearPdfData(String pdfPath) async {
    try {
      final String key = _getStorageKey(pdfPath);
      await _deleteFile(key);
      print('PDF verileri silindi: $pdfPath');
    } catch (e) {
      print('PDF verileri silinirken hata: $e');
    }
  }

  // PDF dosyasının var olup olmadığını kontrol etme
  Future<bool> hasPdfData(String pdfPath) async {
    try {
      final String key = _getStorageKey(pdfPath);
      final data = await _loadFromFile(key);
      return data != null;
    } catch (e) {
      print('PDF veri kontrolü sırasında hata: $e');
      return false;
    }
  }

  // PDF dosyasının son değiştirilme tarihini alma
  Future<DateTime?> getPdfLastModified(String pdfPath) async {
    try {
      final String key = _getStorageKey(pdfPath);
      final data = await _loadFromFile(key);

      if (data != null && data.containsKey('timestamp')) {
        return DateTime.fromMillisecondsSinceEpoch(data['timestamp']);
      }
      return null;
    } catch (e) {
      print('PDF son değiştirilme tarihi alınamadı: $e');
      return null;
    }
  }

  // PDF dosyasının boyutunu alma
  int? getPdfFileSize(String pdfPath) {
    try {
      final file = File(pdfPath);
      if (file.existsSync()) {
        return file.lengthSync();
      }
    } catch (e) {
      print('PDF dosya boyutu alınamadı: $e');
    }
    return null;
  }

  // Storage key oluşturma
  String _getStorageKey(String pdfPath) {
    final fileName = path.basename(pdfPath);
    return 'pdf_drawing_$fileName';
  }

  // Dosya tabanlı storage metodları
  Future<void> _saveToFile(String key, Map<String, dynamic> data) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$key.json');
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print('Dosya kaydetme hatası: $e');
      // Hata durumunda bellekte tut
      _pdfCache[key] = data;
    }
  }

  Future<Map<String, dynamic>?> _loadFromFile(String key) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$key.json');

      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content);
      }

      // Dosya yoksa cache'ten kontrol et
      return _pdfCache[key];
    } catch (e) {
      print('Dosya yükleme hatası: $e');
      // Hata durumunda cache'ten yükle
      return _pdfCache[key];
    }
  }

  Future<void> _deleteFile(String key) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$key.json');
      if (await file.exists()) {
        await file.delete();
      }
      // Cache'ten de sil
      _pdfCache.remove(key);
    } catch (e) {
      print('Dosya silme hatası: $e');
      // Cache'ten sil
      _pdfCache.remove(key);
    }
  }

  // Bellek cache'i (fallback için)
  static final Map<String, Map<String, dynamic>> _pdfCache = {};
}
