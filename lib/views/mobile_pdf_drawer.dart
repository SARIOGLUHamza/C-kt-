import 'dart:io';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
// import 'package:deneme/core/utils/precise_coordinate_system.dart'; // Artık yok
import 'package:deneme/models/colored_note.dart';
import 'package:deneme/controllers/note_controller.dart';
import 'package:get/get.dart';
import 'package:deneme/controllers/simple_controller.dart';

// Çizim noktası modeli
class DrawingPoint {
  final Offset offset;
  final Color color;
  final double strokeWidth;
  final int pageNumber;

  DrawingPoint({
    required this.offset,
    required this.color,
    required this.strokeWidth,
    required this.pageNumber,
  });

  Map<String, dynamic> toJson() => {
    'dx': offset.dx,
    'dy': offset.dy,
    'color': color.value,
    'strokeWidth': strokeWidth,
    'pageNumber': pageNumber,
  };

  factory DrawingPoint.fromJson(Map<String, dynamic> json) => DrawingPoint(
    offset: Offset(json['dx'], json['dy']),
    color: Color(json['color']),
    strokeWidth: json['strokeWidth'],
    pageNumber: json['pageNumber'],
  );
}

// Not modeli
class Note {
  final String id;
  final String text;
  final Offset position;
  final int pageNumber;
  final DateTime createdAt;

  Note({
    required this.id,
    required this.text,
    required this.position,
    required this.pageNumber,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'position': {'dx': position.dx, 'dy': position.dy},
    'pageNumber': pageNumber,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'],
    text: json['text'],
    position: Offset(json['position']['dx'], json['position']['dy']),
    pageNumber: json['pageNumber'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

// Çizim painter'ı
class DrawingPainter extends CustomPainter {
  final List<DrawingPoint> points;
  final List<Note> notes;

  DrawingPainter({required this.points, required this.notes});

  @override
  void paint(Canvas canvas, Size size) {
    // Çizimleri çiz - geliştirilmiş path sistemi
    if (points.isNotEmpty) {
      // Çizimleri renk ve kalınlığa göre grupla
      Map<String, List<DrawingPoint>> groupedPoints = {};
      for (var point in points) {
        String key = '${point.color.value}_${point.strokeWidth}';
        groupedPoints[key] ??= [];
        groupedPoints[key]!.add(point);
      }

      // Her grup için smooth path çiz
      for (var group in groupedPoints.values) {
        if (group.isNotEmpty) {
          final paint =
              Paint()
                ..color = group.first.color
                ..strokeWidth = group.first.strokeWidth
                ..strokeCap = StrokeCap.round
                ..strokeJoin = StrokeJoin.round
                ..style = PaintingStyle.stroke;

          final path = Path();
          for (int i = 0; i < group.length; i++) {
            if (i == 0) {
              path.moveTo(group[i].offset.dx, group[i].offset.dy);
            } else {
              path.lineTo(group[i].offset.dx, group[i].offset.dy);
            }
          }
          canvas.drawPath(path, paint);
        }
      }
    }

    // Notları çiz
    for (final note in notes) {
      _drawNote(canvas, note);
    }
  }

  void _drawNote(Canvas canvas, Note note) {
    // Gelişmiş not görünümü - daha büyük ve okunabilir

    // Not kutusu boyutunu hesapla
    final textPainter = TextPainter(
      text: TextSpan(
        text: note.text,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: 150);

    // Not kutusu
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        note.position.dx,
        note.position.dy,
        textPainter.width + 16,
        textPainter.height + 16,
      ),
      const Radius.circular(8),
    );

    // Gölge
    final shadowPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawRRect(rect.shift(const Offset(2, 2)), shadowPaint);

    // Not arka planı
    final backgroundPaint =
        Paint()
          ..color = Colors.amber.shade200.withOpacity(0.97)
          ..style = PaintingStyle.fill;
    canvas.drawRRect(rect, backgroundPaint);

    // Not kenarlığı
    final borderPaint =
        Paint()
          ..color = Colors.orange.shade400
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawRRect(rect, borderPaint);

    // Not ikonu (sol üst köşe)
    final iconPaint =
        Paint()
          ..color = Colors.orange.shade600
          ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(note.position.dx + 8, note.position.dy + 8),
      6,
      iconPaint,
    );

    // İkon içinde "N" harfi
    final iconTextPainter = TextPainter(
      text: const TextSpan(
        text: 'N',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    iconTextPainter.layout();
    iconTextPainter.paint(
      canvas,
      Offset(
        note.position.dx + 8 - iconTextPainter.width / 2,
        note.position.dy + 8 - iconTextPainter.height / 2,
      ),
    );

    // Not metni
    textPainter.paint(
      canvas,
      Offset(note.position.dx + 8, note.position.dy + 20),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final void Function(Color) onColorSelected;
  const ColorPickerDialog({
    Key? key,
    required this.initialColor,
    required this.onColorSelected,
  }) : super(key: key);
  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _selectedColor;
  final List<Color> _colors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.brown,
    Colors.pink,
    Colors.teal,
    Colors.amber.shade800,
  ];
  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Not Rengi:', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children:
              _colors
                  .map(
                    (color) => GestureDetector(
                      onTap: () {
                        setState(() => _selectedColor = color);
                        widget.onColorSelected(color);
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                _selectedColor == color
                                    ? Colors.black
                                    : Colors.grey.shade300,
                            width: _selectedColor == color ? 3 : 1,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }
}

class MobilePdfDrawer extends StatefulWidget {
  final String pdfPath;
  const MobilePdfDrawer({super.key, required this.pdfPath});

  @override
  State<MobilePdfDrawer> createState() => _MobilePdfDrawerState();
}

class _MobilePdfDrawerState extends State<MobilePdfDrawer> {
  // Controllers
  PDFViewController? _pdfController;

  final SimpleController _simpleController = Get.find<SimpleController>();
  late NoteController _noteController;

  // PDF durumu
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isReady = false;
  String _actualPdfPath = ''; // Gerçekte açılan PDF'in yolu

  // Sadece not verileri (çizim yok)
  List<ColoredNote> _notes = <ColoredNote>[];
  List<ColoredNote> _currentPageNotes = <ColoredNote>[];

  // UI durumu
  bool _showTools = false;
  String _fileName = '';
  String _fileSize = '';

  // PDF boyut bilgileri
  Size _viewerSize = Size.zero;
  Size _pageSize = Size.zero;

  bool _isNoteMode = false; // Not ekleme modu

  String get _pdfKey =>
      path.basename(_actualPdfPath.isEmpty ? widget.pdfPath : _actualPdfPath);

  @override
  void initState() {
    super.initState();
    _noteController = NoteController(_pdfKey);
    _initializePdf();
  }

  /// PDF'i başlat - önce gömülmüş versiyon kontrol et
  Future<void> _initializePdf() async {
    try {
      final embeddedVersion = await _simpleController.getLatestEmbeddedVersion(
        widget.pdfPath,
      );
      if (embeddedVersion != null) {
        _actualPdfPath = embeddedVersion;
        await _simpleController.saveLastEmbeddedPdf(embeddedVersion);
      } else {
        _actualPdfPath = widget.pdfPath;
      }
      await _loadDrawingData();
      setState(() {
        _isReady = true;
      });
    } catch (e) {
      print('❌ PDF başlatma hatası: $e');
    }
  }

  /// Not verilerini yükle
  Future<void> _loadDrawingData() async {
    try {
      final notes = await _noteController.loadNotes();
      setState(() {
        _notes = notes;
      });
      _updateCurrentPageData();
    } catch (e) {
      print('❌ Not verileri yüklenirken hata: $e');
    }
  }

  /// Not verilerini kaydet
  Future<void> _saveDrawingData() async {
    await _noteController.saveNotes(_notes);
  }

  /// Mevcut sayfa notlarını güncelle
  void _updateCurrentPageData() {
    setState(() {
      _currentPageNotes =
          _notes.where((n) => n.pageNumber == _currentPage).toList();
    });
  }

  /// Not ekle (hassas koordinat sistemi ile)
  void _addNote(Offset localPosition) {
    if (_viewerSize == Size.zero || _pageSize == Size.zero) return;
    _showNoteDialog(localPosition);
  }

  /// Not dialog'u göster
  void _showNoteDialog(Offset position) {
    final textController = TextEditingController();
    Color selectedColor = Colors.black;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Not Ekle',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    hintText: 'Notunuzu yazın...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                ColorPickerDialog(
                  initialColor: selectedColor,
                  onColorSelected: (color) {
                    selectedColor = color;
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (textController.text.isNotEmpty) {
                    _addNoteWithColor(
                      position,
                      selectedColor,
                      textController.text,
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text('Ekle'),
              ),
            ],
          ),
    );
  }

  /// Not ekle (hassas koordinat sistemi ile) ve rengi belirle
  void _addNoteWithColor(Offset position, Color color, String text) {
    final newNote = ColoredNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      position: position,
      pageNumber: _currentPage,
      createdAt: DateTime.now(),
      color: color,
      originalPageSize: _pageSize,
      viewerSize: _viewerSize,
    );
    setState(() {
      _notes.add(newNote);
      _currentPageNotes.add(newNote);
    });
    _saveDrawingData();
  }

  // _embedToPdf fonksiyonu ve PreciseCoordinateSystem ile ilgili tüm kodlar kaldırılacak
  // PDF'e gömme butonu ve çağrıları kaldırılacak

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_fileName.isNotEmpty ? _fileName : 'PDF Not'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _isNoteMode ? Icons.sticky_note_2 : Icons.sticky_note_2_outlined,
            ),
            tooltip: _isNoteMode ? 'Not Ekleme Modunu Kapat' : 'Not Ekle',
            onPressed: () {
              setState(() {
                _isNoteMode = !_isNoteMode;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: _actualPdfPath,
            onViewCreated: (controller) {
              _pdfController = controller;
            },
            onPageChanged: (page, total) async {
              final size = MediaQuery.of(context).size;
              setState(() {
                _currentPage = page ?? 1;
                _totalPages = total ?? 0;
                _pageSize = size;
                _viewerSize = size;
              });
              _updateCurrentPageData();
            },
            onRender: (pages) async {
              final size = MediaQuery.of(context).size;
              setState(() {
                _totalPages = pages ?? 0;
                _pageSize = size;
                _viewerSize = size;
              });
            },
            onPageError: (page, error) {
              print('Sayfa $page yüklenirken hata: $error');
            },
            onError: (error) {
              print('PDF yüklenirken hata: $error');
            },
            onLinkHandler: (uri) {
              print('Link tıklandı: $uri');
            },
          ),
          // Sadece not ekleme modunda GestureDetector aktif
          if (_isNoteMode)
            Positioned.fill(
              child: GestureDetector(
                onTapDown: (details) => _addNote(details.localPosition),
                child: Container(color: Colors.transparent),
              ),
            ),
          // Notları göster
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: PreciseNotePainter(
                  notes: _currentPageNotes, // Artık ColoredNote tipinde
                  viewerSize: _viewerSize,
                  pageSize: _pageSize,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Sadece notları çizen painter
class PreciseNotePainter extends CustomPainter {
  final List<ColoredNote> notes;
  final Size viewerSize;
  final Size pageSize;
  PreciseNotePainter({
    required this.notes,
    required this.viewerSize,
    required this.pageSize,
  });
  @override
  void paint(Canvas canvas, Size size) {
    if (viewerSize == Size.zero || pageSize == Size.zero) return;
    for (final note in notes) {
      final viewerPosition = Offset(
        note.position.dx,
        note.position.dy,
      ); // PreciseCoordinateSystem.transformToViewerCoordinates(note.position, viewerSize, pageSize); // Artık kullanılmıyor
      final baseFontSize = 13.0;
      final scaleFactor = viewerSize.width / 400.0;
      final fontSize = baseFontSize * scaleFactor;
      final textPainter = TextPainter(
        text: TextSpan(
          text: note.text,
          style: TextStyle(
            color: note.color,
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: 150 * scaleFactor);
      final padding = 8.0 * scaleFactor;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          viewerPosition.dx,
          viewerPosition.dy,
          textPainter.width + (padding * 2),
          textPainter.height + (padding * 2),
        ),
        Radius.circular(12 * scaleFactor),
      );
      final paint =
          Paint()
            ..color = note.color.withOpacity(0.25)
            ..style = PaintingStyle.fill;
      canvas.drawRRect(rect, paint);
      final borderPaint =
          Paint()
            ..color = note.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5 * scaleFactor;
      canvas.drawRRect(rect, borderPaint);
      textPainter.paint(
        canvas,
        Offset(viewerPosition.dx + padding, viewerPosition.dy + padding),
      );
    }
  }

  Offset _transformToViewerCoordinates(Offset originalOffset) {
    if (viewerSize == Size.zero || pageSize == Size.zero) return originalOffset;
    final scaleX = viewerSize.width / pageSize.width;
    final scaleY = viewerSize.height / pageSize.height;
    return Offset(originalOffset.dx * scaleX, originalOffset.dy * scaleY);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
