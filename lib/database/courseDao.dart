import 'package:deneme/database/database_helper.dart';
import 'package:deneme/models/course.dart';

class CourseDao {
  Future<List<Course>> getAllCourses() async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> maps = await db.query('courses');

    return List.generate(maps.length, (i) {
      return Course.fromJson(maps[i]);
    });
  }

  Future<int> insertCourse(Course course) async {
    final db = await DatabaseHelper().database;
    return await db.insert('courses', {
      'name': course.name,
      'description': course.description,
    });
  }

  Future<int> updateCourse(Course course) async {
    final db = await DatabaseHelper().database;
    return await db.update(
      'courses',
      {'name': course.name, 'description': course.description},
      where: 'id = ?',
      whereArgs: [course.id],
    );
  }

  Future<int> deleteCourse(int courseId) async {
    final db = await DatabaseHelper().database;
    return await db.delete('courses', where: 'id = ?', whereArgs: [courseId]);
  }
}
