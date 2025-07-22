import 'package:deneme/database/database_helper.dart';
import 'package:deneme/models/week.dart';
import 'package:sqflite/sqflite.dart';

class WeekDao {
  Future<List<Week>> getAllWeeks() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query('weeks');

    return List.generate(maps.length, (i) {
      return Week.fromMap(maps[i]);
    });
  }

  Future<List<Week>> getWeeksByCourse(int courseId) async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'weeks',
      where: 'course_id = ?',
      whereArgs: [courseId],
      orderBy: 'week_number ASC',
    );

    return List.generate(maps.length, (i) {
      return Week.fromMap(maps[i]);
    });
  }

  Future<int> insertWeek(Week week) async {
    final db = await DatabaseHelper().database;
    return await db.insert('weeks', {
      'course_id': week.courseId,
      'title': week.title,
      'description': week.description,
      'week_number': week.weekNumber,
      'created_at': week.createdAt,
      'content': week.content,
      'is_favorite': week.isFavorite.value ? 1 : 0,
    });
  }

  Future<int> updateWeek(Week week) async {
    final db = await DatabaseHelper().database;
    return await db.update(
      'weeks',
      {
        'course_id': week.courseId,
        'title': week.title,
        'description': week.description,
        'week_number': week.weekNumber,
        'created_at': week.createdAt,
        'content': week.content,
        'is_favorite': week.isFavorite.value ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [week.id],
    );
  }

  Future<int> deleteWeek(int weekId) async {
    final db = await DatabaseHelper().database;
    return await db.delete('weeks', where: 'id = ?', whereArgs: [weekId]);
  }

  Future<int> getFavoriteWeekCountByCourse(int courseId) async {
    final db = await DatabaseHelper().database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM weeks WHERE course_id = ? AND is_favorite = 1',
      [courseId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Eski kayıtların content alanını düzeltir: Eğer content boşsa, '[]' yapar
  Future<void> fixEmptyContentFields() async {
    final db = await DatabaseHelper().database;
    // Boş veya sadece boşluk olan content'leri bul
    final List<Map<String, dynamic>> maps = await db.query(
      'weeks',
      where: "content IS NULL OR TRIM(content) = ''",
    );
    for (final map in maps) {
      final id = map['id'];
      await db.update(
        'weeks',
        {'content': '[]'},
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Week kaydı düzeltildi (id: $id)');
    }
    print('Tüm boş content alanları güncellendi.');
  }
}
