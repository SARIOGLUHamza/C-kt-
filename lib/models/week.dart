import 'package:get/get.dart';

class MediaFile {
  int? id;
  int? weekId;
  String fileName;
  String filePath;
  String fileType; // 'pdf', 'image', 'text'
  int createdAt;

  MediaFile({
    this.id,
    this.weekId,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  MediaFile.fromMap(Map<String, dynamic> map)
    : id = map['id'],
      weekId = map['week_id'],
      fileName = map['file_name'],
      filePath = map['file_path'],
      fileType = map['file_type'],
      createdAt = map['created_at'];

  Map<String, dynamic> toMap() => {
    'id': id,
    'week_id': weekId,
    'file_name': fileName,
    'file_path': filePath,
    'file_type': fileType,
    'created_at': createdAt,
  };
}

class Week {
  int? id;
  int? courseId;
  String title;
  String? description;
  int weekNumber;
  int createdAt;
  String content;
  RxBool isFavorite;
  List<String> attachedFiles;
  RxList<MediaFile> mediaFiles;

  Week({
    this.id,
    this.courseId,
    required this.title,
    this.description,
    required this.weekNumber,
    int? createdAt,
    String? content,
    bool isFavorite = false,
    List<String>? attachedFiles,
    List<MediaFile>? mediaFiles,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
       content = content ?? '',
       isFavorite = isFavorite.obs,
       attachedFiles = attachedFiles ?? [],
       mediaFiles = (mediaFiles ?? <MediaFile>[]).obs;

  Week.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      courseId = json['course_id'],
      title = json['title'],
      description = json['description'],
      weekNumber = json['week_number'] ?? 0,
      createdAt = json['created_at'] ?? DateTime.now().millisecondsSinceEpoch,
      content = json['content']?.toString() ?? '',
      isFavorite = (json['isFavorite'] ?? false).obs,
      attachedFiles = List<String>.from(json['attachedFiles'] ?? []),
      mediaFiles = <MediaFile>[].obs;

  Week.fromMap(Map<String, dynamic> map)
    : id = map['id'],
      courseId = map['course_id'],
      title = map['title'],
      description = map['description'],
      weekNumber = map['week_number'],
      createdAt = map['created_at'],
      content = map['content'] ?? '',
      isFavorite = ((map['is_favorite'] ?? 0) == 1).obs,
      attachedFiles = [],
      mediaFiles = <MediaFile>[].obs;

  Map<String, dynamic> toJson() => {
    'id': id,
    'course_id': courseId,
    'title': title,
    'description': description,
    'week_number': weekNumber,
    'created_at': createdAt,
    'content': content,
    'isFavorite': isFavorite.value,
    'attachedFiles': attachedFiles,
  };

  Map<String, dynamic> toMap() => {
    'id': id,
    'course_id': courseId,
    'title': title,
    'description': description,
    'week_number': weekNumber,
    'created_at': createdAt,
    'content': content,
    'is_favorite': isFavorite.value ? 1 : 0,
  };
}
