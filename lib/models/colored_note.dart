import 'dart:ui';

class ColoredNote {
  String id;
  String text;
  Offset position;
  int pageNumber;
  DateTime createdAt;
  Color color;
  Size originalPageSize;
  Size viewerSize;
  ColoredNote({
    required this.id,
    required this.text,
    required this.position,
    required this.pageNumber,
    required this.createdAt,
    required this.color,
    required this.originalPageSize,
    required this.viewerSize,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'position': {'dx': position.dx, 'dy': position.dy},
    'pageNumber': pageNumber,
    'createdAt': createdAt.toIso8601String(),
    'color': color.value,
    'originalPageSize': {
      'width': originalPageSize.width,
      'height': originalPageSize.height,
    },
    'viewerSize': {'width': viewerSize.width, 'height': viewerSize.height},
  };
  factory ColoredNote.fromJson(Map<String, dynamic> json) => ColoredNote(
    id: json['id'],
    text: json['text'],
    position: Offset(json['position']['dx'], json['position']['dy']),
    pageNumber: json['pageNumber'],
    createdAt: DateTime.parse(json['createdAt']),
    color: Color(json['color']),
    originalPageSize: Size(
      json['originalPageSize']['width'],
      json['originalPageSize']['height'],
    ),
    viewerSize: Size(json['viewerSize']['width'], json['viewerSize']['height']),
  );
}
