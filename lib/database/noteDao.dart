import 'package:deneme/database/database_helper.dart';
import 'package:deneme/models/note.dart';

class NoteDao {
  Future<List<Note>> getAllNotes() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query('notes');

    return List.generate(maps.length, (i) {
      return Note.fromMap(maps[i]);
    });
  }

  Future<List<Note>> getNotesByWeek(int weekId) async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'week_id = ?',
      whereArgs: [weekId],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return Note.fromMap(maps[i]);
    });
  }

  Future<int> insertNote(Note note) async {
    final db = await DatabaseHelper().database;
    return await db.insert('notes', {
      'week_id': note.weekId,
      'content': note.content,
      'page_number': note.pageNumber,
      'x_position': note.xPosition,
      'y_position': note.yPosition,
      'created_at': note.createdAt,
    });
  }

  Future<int> updateNote(Note note) async {
    final db = await DatabaseHelper().database;
    return await db.update(
      'notes',
      {
        'week_id': note.weekId,
        'content': note.content,
        'page_number': note.pageNumber,
        'x_position': note.xPosition,
        'y_position': note.yPosition,
        'created_at': note.createdAt,
      },
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int noteId) async {
    final db = await DatabaseHelper().database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [noteId]);
  }
}
