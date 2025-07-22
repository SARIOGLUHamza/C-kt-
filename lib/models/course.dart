import 'package:get/get.dart';
import 'week.dart';

class Course {
  int id;
  String name;
  String? description;
  RxList<Week> weeks;
  RxInt favoriteCount;
  RxInt weekCount;

  Course({
    required this.id,
    required this.name,
    this.description,
    RxList<Week>? weeks,
    RxInt? favoriteCount,
    RxInt? weekCount,
  }) : weeks = weeks ?? <Week>[].obs,
       favoriteCount = favoriteCount ?? 0.obs,
       weekCount = weekCount ?? 0.obs;

  factory Course.fromJson(Map<String, dynamic> json) {
    // JSON'dan gelen weeks listesini tip güvenli şekilde dönüştür
    final rawWeeks = json['weeks'] ?? [];
    final List<Week> weekList =
        rawWeeks is List
            ? rawWeeks
                .map(
                  (e) =>
                      e is Week ? e : Week.fromJson(e as Map<String, dynamic>),
                )
                .toList()
            : <Week>[];
    return Course(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      weeks: weekList.obs,
      weekCount: json['weekCount'],
      favoriteCount: json['favoriteCount'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'weeks': weeks.map((w) => w.toJson()).toList(),
    'weekCount': weekCount,
    'favoriteCount': favoriteCount,
  };
}
