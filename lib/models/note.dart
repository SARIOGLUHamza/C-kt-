class Note {
  int? id;
  int weekId;
  String content;
  int pageNumber;
  double xPosition;
  double yPosition;
  int createdAt;

  Note({
    this.id,
    required this.weekId,
    required this.content,
    required this.pageNumber,
    required this.xPosition,
    required this.yPosition,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Note.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      weekId = json['week_id'],
      content = json['content'],
      pageNumber = json['page_number'],
      xPosition = json['x_position'].toDouble(),
      yPosition = json['y_position'].toDouble(),
      createdAt = json['created_at'];

  Note.fromMap(Map<String, dynamic> map)
    : id = map['id'],
      weekId = map['week_id'],
      content = map['content'],
      pageNumber = map['page_number'],
      xPosition = map['x_position'].toDouble(),
      yPosition = map['y_position'].toDouble(),
      createdAt = map['created_at'];

  Map<String, dynamic> toJson() => {
    'id': id,
    'week_id': weekId,
    'content': content,
    'page_number': pageNumber,
    'x_position': xPosition,
    'y_position': yPosition,
    'created_at': createdAt,
  };

  Map<String, dynamic> toMap() => {
    'id': id,
    'week_id': weekId,
    'content': content,
    'page_number': pageNumber,
    'x_position': xPosition,
    'y_position': yPosition,
    'created_at': createdAt,
  };
}
