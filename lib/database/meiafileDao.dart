import 'package:deneme/database/database_helper.dart';
import 'package:deneme/models/week.dart';

class MediaFileDao {
  // Medya dosyasını kaydet
  Future<int> insertMediaFile(MediaFile mediaFile) async {
    final db = await DatabaseHelper().database;
    return await db.insert('media_files', mediaFile.toMap());
  }

  // Belirli bir week'e ait medya dosyalarını getir
  Future<List<MediaFile>> getMediaFilesByWeekId(int weekId) async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'media_files',
      where: 'week_id = ?',
      whereArgs: [weekId],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return MediaFile.fromMap(maps[i]);
    });
  }

  // Medya dosyasını sil
  Future<int> deleteMediaFile(int id) async {
    final db = await DatabaseHelper().database;
    return await db.delete('media_files', where: 'id = ?', whereArgs: [id]);
  }

  // Belirli bir week'in tüm medya dosyalarını sil
  Future<int> deleteMediaFilesByWeekId(int weekId) async {
    final db = await DatabaseHelper().database;
    return await db.delete(
      'media_files',
      where: 'week_id = ?',
      whereArgs: [weekId],
    );
  }

  // Medya dosyasını güncelle
  Future<int> updateMediaFile(MediaFile mediaFile) async {
    final db = await DatabaseHelper().database;
    return await db.update(
      'media_files',
      mediaFile.toMap(),
      where: 'id = ?',
      whereArgs: [mediaFile.id],
    );
  }
}
