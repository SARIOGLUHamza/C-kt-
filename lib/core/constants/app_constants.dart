// Uygulama genelinde kullanılan sabitler
class AppConstants {
  // Uygulama bilgileri
  static const String appName = 'Dijital Defter';
  static const String appVersion = '1.0.0';

  // Renkler
  static const int primaryColorValue = 0xFF3F51B5; // Indigo
  static const int accentColorValue = 0xFFFF9800; // Orange

  // Boyutlar
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Animasyon süreleri
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Dosya uzantıları
  static const List<String> supportedPdfExtensions = ['pdf'];
  static const List<String> supportedDocumentExtensions = [
    'pdf',
    'ppt',
    'pptx',
  ];
  static const List<String> supportedAudioExtensions = [
    'm4a',
    'aac',
    'wav',
    'mp3',
  ];

  // Storage anahtarları
  static const String coursesStorageKey = 'courses_data';
  static const String weeksStorageKey = 'weeks_data';
  static const String pdfAnnotationsPrefix = 'pdf_annotations';

  // Mesajlar
  static const String noFavoritesMessage = 'Henüz favori Bölüm eklenmemiş';
  static const String addCourseHint = 'Ders adını girin';
  static const String addWeekHint = 'Bölüm başlığını girin';

  // Hata mesajları
  static const String generalError = 'Bir hata oluştu';
  static const String fileNotFoundError = 'Dosya bulunamadı';
  static const String permissionError = 'İzin gerekli';
}
