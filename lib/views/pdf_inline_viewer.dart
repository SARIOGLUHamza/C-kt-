// DİKKAT: flutter_pdfview paketi scroll ile sayfa değişimini destekler.
// Her seferinde bir sayfa gösterilir, swipe ile sayfa değiştirilebilir.

import 'dart:io';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

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

// Not painter'ı (sadece notları çizer)
class NotePainter extends CustomPainter {
  final List<Note> notes;
  NotePainter({required this.notes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final note in notes) {
      _drawNote(canvas, note);
    }
  }

  void _drawNote(Canvas canvas, Note note) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: note.text,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontFamily: 'Inter',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: 160);

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        note.position.dx,
        note.position.dy,
        textPainter.width + 16,
        textPainter.height + 16,
      ),
      const Radius.circular(12),
    );

    final shadowPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(rect.shift(const Offset(2, 2)), shadowPaint);

    final paint =
        Paint()
          ..color = Colors.amber.shade200
          ..style = PaintingStyle.fill;
    canvas.drawRRect(rect, paint);

    final borderPaint =
        Paint()
          ..color = Colors.orange.shade300
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
    canvas.drawRRect(rect, borderPaint);

    textPainter.paint(
      canvas,
      Offset(note.position.dx + 8, note.position.dy + 8),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PdfInlineViewer extends StatefulWidget {
  final String pdfPath;
  const PdfInlineViewer({super.key, required this.pdfPath});

  @override
  State<PdfInlineViewer> createState() => _PdfInlineViewerState();
}

class _PdfInlineViewerState extends State<PdfInlineViewer>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _fileExists = false;
  String _fileSize = '';
  String _fileName = '';
  int _currentPage = 0;
  int _totalPages = 1;
  bool _isError = false;
  String _errorMessage = '';
  // PDFView için controller
  PDFViewController? _pdfViewController;

  // Sadece notlar
  List<Note> _notes = [];
  final List<Note> _currentPageNotes = [];
  final TextEditingController _noteController = TextEditingController();

  String get _pdfKey => path.basename(widget.pdfPath);

  // Not ekleme modu
  bool _isNoteMode = false;

  // Animasyonlar
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializeStorage();
    _checkFile();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeStorage() async {
    try {
      await _loadAnnotations();
    } catch (e) {
      print('Storage başlatma hatası: $e');
    }
  }

  Future<void> _loadAnnotations() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final notesFile = File('${directory.path}/notes_$_pdfKey.json');

      if (await notesFile.exists()) {
        final notesJson = jsonDecode(await notesFile.readAsString()) as List;
        _notes =
            notesJson
                .map((json) => Note.fromJson(json as Map<String, dynamic>))
                .toList();
      }

      _updateCurrentPageAnnotations();
      print('Yüklenen not sayısı:  [38;5;2m${_notes.length} [0m');
    } catch (e) {
      print('Açıklama yükleme hatası: $e');
    }
  }

  Future<void> _saveAnnotations() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final notesFile = File('${directory.path}/notes_$_pdfKey.json');
      final notesJson = _notes.map((note) => note.toJson()).toList();
      await notesFile.writeAsString(jsonEncode(notesJson));
      print('Kaydedilen not sayısı:  [38;5;2m${_notes.length} [0m');
    } catch (e) {
      print('Açıklama kaydetme hatası: $e');
    }
  }

  void _updateCurrentPageAnnotations() {
    _currentPageNotes.clear();
    _currentPageNotes.addAll(
      _notes.where((note) => note.pageNumber == _currentPage),
    );
    setState(() {});
  }

  Future<void> _checkFile() async {
    try {
      final file = File(widget.pdfPath);
      _fileExists = await file.exists();
      if (_fileExists) {
        final size = await file.length();
        _fileSize = _formatFileSize(size);
        _fileName = widget.pdfPath.split('/').last;
        // PDFView ile toplam sayfa sayısı ilk açılışta alınacak
      } else {
        _isError = true;
        _errorMessage = 'PDF dosyası bulunamadı';
      }
    } catch (e) {
      _isError = true;
      _errorMessage = 'Dosya kontrol hatası: $e';
    }
    setState(() {
      _isLoading = false;
    });
    _animationController.forward();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _onPageChanged(int page) {
    if (page != _currentPage) {
      setState(() {
        _currentPage = page;
        _updateCurrentPageAnnotations();
      });
      print('PDF Viewer sayfası değişti: $_currentPage');
    }
  }

  void _toggleNoteMode() {
    setState(() {
      _isNoteMode = !_isNoteMode;
    });
    if (_isNoteMode) {
      _showSnackBar('Not ekleme modu aktif', Icons.note_add, Colors.blue);
    }
  }

  void _showSnackBar(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _addNote(Offset position) {
    if (!_isNoteMode) return;
    _noteController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.note_add,
                    color: Colors.blue.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Not Ekle',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PDF üzerine eklemek istediğiniz notu yazın:',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: 'Notunuzu buraya yazın...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.blue.shade400,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  maxLines: 3,
                  autofocus: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () {
                  final text = _noteController.text.trim();
                  if (text.isNotEmpty) {
                    final note = Note(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      text: text,
                      position: position,
                      pageNumber: _currentPage,
                      createdAt: DateTime.now(),
                    );
                    setState(() {
                      _notes.add(note);
                      _currentPageNotes.add(note);
                    });
                    _saveAnnotations();
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Ekle',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );
  }

  void _clearCurrentPageNotes() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.warning_amber,
                    color: Colors.red.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Sayfayı Temizle',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            content: const Text(
              'Bu sayfadaki tüm notlar kalıcı olarak silinecek. Bu işlem geri alınamaz.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _notes.removeWhere(
                      (note) => note.pageNumber == _currentPage,
                    );
                    _updateCurrentPageAnnotations();
                  });
                  _saveAnnotations();
                  Navigator.of(context).pop();
                  _showSnackBar(
                    'Sayfa temizlendi!',
                    Icons.check_circle,
                    Colors.green,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Temizle',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_isError || !_fileExists) {
      return Scaffold(body: Center(child: Text(_errorMessage)));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_fileName),
        actions: [
          IconButton(
            icon: Icon(
              _isNoteMode ? Icons.sticky_note_2 : Icons.sticky_note_2_outlined,
            ),
            onPressed: _toggleNoteMode,
          ),
          IconButton(
            icon: Icon(Icons.clear_all),
            onPressed: _clearCurrentPageNotes,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Toplam $_totalPages sayfa • Not: ${_notes.length}'),
          ),
          Expanded(
            child: Stack(
              children: [
                PDFView(
                  filePath: widget.pdfPath,
                  enableSwipe: true,
                  swipeHorizontal: false,
                  autoSpacing: true,
                  pageFling: true,
                  onRender: (pages) {
                    setState(() {
                      _totalPages = pages ?? 1;
                    });
                  },
                  onViewCreated: (controller) {
                    _pdfViewController = controller;
                  },
                  onPageChanged: (page, total) {
                    if (page != null && page != _currentPage) {
                      setState(() {
                        _currentPage = page;
                        _updateCurrentPageAnnotations();
                      });
                    }
                  },
                  onError: (error) {
                    setState(() {
                      _isError = true;
                      _errorMessage = 'PDF yüklenirken hata: $error';
                    });
                  },
                  onPageError: (page, error) {
                    setState(() {
                      _isError = true;
                      _errorMessage = 'Sayfa $page yüklenirken hata: $error';
                    });
                  },
                ),
                if (_isNoteMode)
                  Positioned.fill(
                    child: GestureDetector(
                      onTapDown: (details) {
                        RenderBox box = context.findRenderObject() as RenderBox;
                        Offset localPosition = box.globalToLocal(
                          details.globalPosition,
                        );
                        _addNote(localPosition);
                      },
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      foregroundPainter: NotePainter(notes: _currentPageNotes),
                      child: Container(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
