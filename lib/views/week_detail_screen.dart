import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:signature/signature.dart';
import 'package:camera/camera.dart';
import 'package:mime/mime.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:deneme/database/meiafileDao.dart';
import 'package:deneme/models/week.dart';
import 'package:deneme/controllers/simple_controller.dart';
import 'package:deneme/core/constants/app_constants.dart';
import 'package:deneme/database/database_helper.dart';
import 'package:deneme/views/mobile_pdf_drawer.dart';
import 'package:deneme/controllers/week_controler.dart';
import 'package:collection/collection.dart'; // Added for firstWhereOrNull
import 'package:image/image.dart' as img;

// Custom File Embed için özel sınıflar
class FileBlockEmbed extends quill.CustomBlockEmbed {
  const FileBlockEmbed(String value) : super(fileType, value);

  static const String fileType = 'file';

  static FileBlockEmbed fromDocument(quill.Document document) =>
      FileBlockEmbed(jsonEncode(document.toDelta().toJson()));

  quill.Document get document =>
      quill.Document.fromJson(jsonDecode(data) as List);
}

// Custom File Widget Builder
class FileEmbedBuilder extends quill.EmbedBuilder {
  @override
  String get key => 'file';

  @override
  Widget build(BuildContext context, quill.EmbedContext embedContext) {
    final data =
        jsonDecode(embedContext.node.value.data) as Map<String, dynamic>;
    final fileName = data['fileName'] as String;
    final filePath = data['filePath'] as String;
    final fileType = data['fileType'] as String;

    final weekState = context.findAncestorStateOfType<_WeekDetailScreenState>();
    final week = weekState?.widget.week;
    final media = week?.mediaFiles.firstWhereOrNull(
      (m) => m.filePath == filePath,
    );

    if (media != null && week != null) {
      return FileWidget(
        key: ValueKey('quill_${media.id}'), // sabit ve benzersiz key
        media: media,
        week: week,
        onDeleteMedia: weekState?._deleteMedia,
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

// Tıklanabilir Dosya Widget'ı
class FileWidget extends StatelessWidget {
  final MediaFile media;
  final Week week;
  final Future<void> Function(MediaFile media)? onDeleteMedia;

  const FileWidget({
    super.key,
    required this.media,
    required this.week,
    this.onDeleteMedia,
  });

  IconData get fileIcon {
    switch (media.fileType) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'presentation':
        return Icons.slideshow;
      case 'audio':
        return Icons.audiotrack;
      case 'handwriting':
      case 'image':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color get fileColor {
    switch (media.fileType) {
      case 'pdf':
        return Colors.red;
      case 'presentation':
        return Colors.orange;
      case 'audio':
        return Colors.green;
      case 'handwriting':
        return Colors.purple;
      case 'image':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  bool get canAnnotate {
    return media.fileType == 'pdf' ||
        media.fileType == 'image' ||
        media.fileType == 'handwriting';
  }

  @override
  Widget build(BuildContext context) {
    // YENİ: Görsel veya handwriting ise AnnotatedImageWidget ile göster
    if (media.fileType == 'image' || media.fileType == 'handwriting') {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showOptionsDialog(context),
            borderRadius: BorderRadius.circular(6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: AnnotatedImageWidget(
                    fileName: media.fileName,
                    filePath: media.filePath,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    media.fileName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: fileColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                if (canAnnotate)
                  Icon(Icons.edit, color: fileColor.withOpacity(0.6), size: 10),
                const SizedBox(width: 2),
                Icon(
                  Icons.open_in_new,
                  color: fileColor.withOpacity(0.6),
                  size: 12,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showOptionsDialog(context),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: fileColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: fileColor.withOpacity(0.2), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(fileIcon, color: fileColor, size: 16),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    media.fileName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: fileColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                if (canAnnotate)
                  Icon(Icons.edit, color: fileColor.withOpacity(0.6), size: 10),
                const SizedBox(width: 2),
                Icon(
                  Icons.open_in_new,
                  color: fileColor.withOpacity(0.6),
                  size: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(media.fileName),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.open_in_new, color: fileColor),
                  title: const Text('Dosyayı Aç'),
                  onTap: () {
                    Navigator.pop(context);
                    _openFile();
                  },
                ),
                if (canAnnotate)
                  ListTile(
                    leading: Icon(Icons.edit, color: fileColor),
                    title: const Text('Not Ekle / Düzenle'),
                    onTap: () {
                      Navigator.pop(context);
                      _openAnnotationEditor(context);
                    },
                  ),
                // --- SİLME SEÇENEĞİ ---
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Sil'),
                  onTap: () {
                    Navigator.pop(context);
                    if (onDeleteMedia != null) {
                      onDeleteMedia!(media);
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _openFile() async {
    try {
      await OpenFile.open(media.filePath);
    } catch (e) {
      Get.snackbar(
        'Hata',
        'Dosya açılamadı: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _openAnnotationEditor(BuildContext context) async {
    if (media.fileType == 'pdf') {
      final simpleController = Get.find<SimpleController>();
      final latestEmbedded = await simpleController.getLatestEmbeddedVersion(
        media.filePath,
      );
      final pathToOpen = latestEmbedded ?? media.filePath;
      Get.to(() => MobilePdfDrawer(pdfPath: pathToOpen));
    } else if (media.fileType == 'image' || media.fileType == 'handwriting') {
      Get.to(
        () => ImageAnnotationScreen(
          fileName: media.fileName,
          filePath: media.filePath,
        ),
      );
    }
  }
}

// PDFAnnotationScreen kaldırıldı - artık PdfInlineViewer kullanılıyor

// Image Annotation Ekranı
class ImageAnnotationScreen extends StatefulWidget {
  final String fileName;
  final String filePath;

  const ImageAnnotationScreen({
    super.key,
    required this.fileName,
    required this.filePath,
  });

  @override
  State<ImageAnnotationScreen> createState() => _ImageAnnotationScreenState();
}

class _ImageAnnotationScreenState extends State<ImageAnnotationScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isTextMode = true;
  List<TextOverlay> _textOverlays = [];
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _loadImageSizeAndDrawing();
  }

  Future<void> _loadImageSizeAndDrawing() async {
    final file = File(widget.filePath);
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    setState(() {
      _imageSize = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
    });
    final appDir = await getApplicationDocumentsDirectory();
    final textFile = File('${appDir.path}/text_${widget.fileName}.json');
    if (await textFile.exists()) {
      final textJson = jsonDecode(await textFile.readAsString()) as List;
      setState(() {
        _textOverlays =
            textJson
                .map((e) => TextOverlay(text: e['text'], x: e['x'], y: e['y']))
                .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_imageSize == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.fileName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAnnotatedImage,
            tooltip: 'Notları Kaydet',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final imageWidth = _imageSize!.width;
          final imageHeight = _imageSize!.height;
          final widgetWidth = constraints.maxWidth;
          final widgetHeight = constraints.maxHeight;
          final imageRect = calculateImageRect(
            imageWidth: imageWidth,
            imageHeight: imageHeight,
            widgetWidth: widgetWidth,
            widgetHeight: widgetHeight,
          );
          return GestureDetector(
            onTapUp: (details) {
              if (_isTextMode) {
                _addTextOverlay(details.localPosition, constraints);
              }
            },
            child: Center(
              child: Container(
                color: Colors.white,
                alignment: Alignment.center,
                child: Stack(
                  children: [
                    Positioned(
                      left: imageRect.left,
                      top: imageRect.top,
                      width: imageRect.width,
                      height: imageRect.height,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(widget.filePath),
                          width: imageRect.width,
                          height: imageRect.height,
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                    // Not kutuları
                    ..._textOverlays.map((overlay) {
                      final shownX =
                          imageRect.left +
                          (overlay.x / imageWidth) * imageRect.width;
                      final shownY =
                          imageRect.top +
                          (overlay.y / imageHeight) * imageRect.height;
                      return Positioned(
                        left: shownX,
                        top: shownY,
                        child: GestureDetector(
                          onTap: () => _editTextOverlay(overlay),
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 2,
                                horizontal: 2,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.yellow.shade100.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.orange.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                overlay.text,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar:
          _isTextMode
              ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: Text(
                                  'Tüm notları silmek istediğinize emin misiniz?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('İptal'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      setState(() {
                                        _textOverlays.clear();
                                      });
                                    },
                                    child: Text('Sil'),
                                  ),
                                ],
                              ),
                        );
                      },
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('Tüm Notları Sil'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    const Icon(
                      Icons.info_outline,
                      color: Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Not eklemek için resme dokunun',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              : null,
    );
  }

  void _addTextOverlay(Offset tapPosition, BoxConstraints constraints) {
    final imageWidth = _imageSize!.width;
    final imageHeight = _imageSize!.height;
    final widgetWidth = constraints.maxWidth;
    final widgetHeight = constraints.maxHeight;
    final imageRect = calculateImageRect(
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      widgetWidth: widgetWidth,
      widgetHeight: widgetHeight,
    );
    if (!imageRect.contains(tapPosition)) return;
    final localX = (tapPosition.dx - imageRect.left) / imageRect.width;
    final localY = (tapPosition.dy - imageRect.top) / imageRect.height;
    final imageX = localX * imageWidth;
    final imageY = localY * imageHeight;
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
            content: TextField(
              controller: _textController,
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_textController.text.isNotEmpty) {
                    setState(() {
                      _textOverlays.add(
                        TextOverlay(
                          text: _textController.text,
                          x: imageX,
                          y: imageY,
                        ),
                      );
                    });
                    _textController.clear();
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

  void _editTextOverlay(TextOverlay overlay) {
    _textController.text = overlay.text;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Notu Düzenle',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: TextField(
              controller: _textController,
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_textController.text.isNotEmpty) {
                    setState(() {
                      overlay.text = _textController.text;
                    });
                    _textController.clear();
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
                child: const Text('Kaydet'),
              ),
            ],
          ),
    );
  }

  Future<void> _saveAnnotatedImage() async {
    try {
      if (_imageSize == null) return;
      final appDir = await getApplicationDocumentsDirectory();
      final textFile = File('${appDir.path}/text_${widget.fileName}.json');
      if (_textOverlays.isNotEmpty) {
        final textData =
            _textOverlays
                .map(
                  (overlay) => {
                    'text': overlay.text,
                    'x': overlay.x,
                    'y': overlay.y,
                  },
                )
                .toList();
        await textFile.writeAsString(jsonEncode(textData));
      }
      Get.snackbar(
        'Başarılı',
        'Notlar kaydedildi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Hata',
        'Kaydetme başarısız: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}

// Text Overlay sınıfı
class TextOverlay {
  String text;
  double x;
  double y;

  TextOverlay({required this.text, required this.x, required this.y});
}

class AnnotatedImageWidget extends StatefulWidget {
  final String fileName;
  final String filePath;
  const AnnotatedImageWidget({
    super.key,
    required this.fileName,
    required this.filePath,
  });

  @override
  State<AnnotatedImageWidget> createState() => _AnnotatedImageWidgetState();
}

class _AnnotatedImageWidgetState extends State<AnnotatedImageWidget> {
  @override
  Widget build(BuildContext context) {
    return Image.file(File(widget.filePath), fit: BoxFit.contain);
  }
}

class WeekDetailScreen extends StatefulWidget {
  const WeekDetailScreen({super.key, required this.week});

  final Week week;

  @override
  State<WeekDetailScreen> createState() => _WeekDetailScreenState();
}

class _WeekDetailScreenState extends State<WeekDetailScreen> {
  final GlobalKey _signatureKey = GlobalKey();
  late quill.QuillController _quillController;
  final MediaFileDao _mediaFileDao = MediaFileDao();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;

  // Ses kayıt sistemi
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  String? _recordingPath;

  // El yazısı sistemi
  SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
  );
  bool _isHandwritingMode = false;

  // Kamera sistemi
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  // State değişkeni ekle
  List<String> _lastEmbedFilePaths = [];
  bool _allowEmbedDelete =
      false; // Sadece özel butonla silmeye izin vermek için flag

  @override
  void initState() {
    super.initState();
    _initializeQuillController();
    _quillController.addListener(_autoSaveContent);
    _loadMediaFiles();
    _initializeRecorder();
    _initializeCamera();
  }

  // _protectEmbeds fonksiyonu ve listener'ı kaldırıldı

  void _initializeQuillController() {
    // Eğer içerik boşsa, Quill editörü için tek satırlık geçerli bir Delta ile başlatıyoruz. Bu, Quill'in beklediği minimum yapıdır ve hata alınmaz.
    const bosDelta = '[{"insert":"\\n"}]';
    final json =
        (widget.week.content == null || widget.week.content.trim().isEmpty)
            ? jsonDecode(bosDelta)
            : jsonDecode(widget.week.content);
    final doc = quill.Document.fromJson(json);
    _quillController = quill.QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
      onReplaceText: (int index, int len, Object? data) {
        // Silmeye engel
        if ((data == null || data == '') && len > 0) {
          final delta = _quillController.document.toDelta();
          int offset = 0;
          for (final op in delta.toList()) {
            final opLen = op.length as int;
            if (offset <= index && index < offset + opLen) {
              if (op.isInsert && op.data is Map) {
                return false; // embed var, silme
              }
            }
            offset += opLen;
          }
        }
        return true;
      },
    );
    _quillController.addListener(_autoSaveContent);
  }

  void _autoSaveContent() async {
    try {
      final deltaJson = _quillController.document.toDelta().toJson();
      // Kontrol karakterlerini temizle
      final cleanedDeltaJson =
          (deltaJson as List).map((op) {
            if (op is Map &&
                op.containsKey('insert') &&
                op['insert'] is String) {
              op['insert'] = (op['insert'] as String).replaceAll(
                RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'),
                '',
              );
            }
            return op;
          }).toList();
      final jsonContent = jsonEncode(cleanedDeltaJson);
      widget.week.content = jsonContent;

      final controller = Get.find<SimpleController>();
      await controller.weekController.updateWeekContent(
        widget.week,
        jsonContent,
      );
    } catch (e) {
      // Hata olursa temiz bir Quill dokümanı başlat
      _quillController = quill.QuillController.basic();
    }
  }

  // _protectEmbeds fonksiyonunu tamamen kaldırıyorum.

  Future<void> _loadMediaFiles() async {
    if (widget.week.id != null) {
      final mediaFiles = await _mediaFileDao.getMediaFilesByWeekId(
        widget.week.id!,
      );
      widget.week.mediaFiles.assignAll(mediaFiles);
    }
  }

  // Ses kayıt sistemi başlatma
  Future<void> _initializeRecorder() async {
    _recorder = FlutterSoundRecorder();

    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Mikrofon izni gerekli');
    }

    await _recorder!.openRecorder();
  }

  // Kamera sistemi başlatma
  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
  }

  // PDF/PPTX dosyası seç ve text'e embed et
  Future<void> _pickDocumentFile() async {
    setState(() => _isLoading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'pptx', 'ppt', 'docx', 'doc'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final mimeType = lookupMimeType(fileName);

        final appDir = await getApplicationDocumentsDirectory();
        final savedFile = await file.copy('${appDir.path}/$fileName');

        String fileType = 'document';
        if (mimeType?.contains('pdf') == true) {
          fileType = 'pdf';
        } else if (mimeType?.contains('presentation') == true) {
          fileType = 'presentation';
        }

        // Veritabanına kaydet
        final mediaFile = MediaFile(
          weekId: widget.week.id,
          fileName: fileName,
          filePath: savedFile.path,
          fileType: fileType,
        );

        await _mediaFileDao.insertMediaFile(mediaFile);
        await _loadMediaFiles();

        // Tıklanabilir dosya widget'ı ekle
        _insertFileEmbed(fileName, savedFile.path, fileType);

        Get.snackbar(
          'Başarılı',
          'Dosya eklendi: $fileName',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Hata',
        'Dosya eklenemedi: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Görsel seç ve text'e embed et
  Future<void> _pickImage() async {
    setState(() => _isLoading = true);

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        await _saveAndEmbedImageFile(File(pickedFile.path), pickedFile.name);
      }
    } catch (e) {
      Get.snackbar(
        'Hata',
        'Görsel eklenemedi: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Kamera ile fotoğraf çek ve embed et
  Future<void> _takePhoto() async {
    if (_cameras == null || _cameras!.isEmpty) {
      Get.snackbar('Hata', 'Kamera bulunamadı');
      return;
    }

    try {
      final result = await Get.to(() => CameraScreen(cameras: _cameras!));
      if (result != null && result is File) {
        final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _saveAndEmbedImageFile(result, fileName);
      }
    } catch (e) {
      Get.snackbar(
        'Hata',
        'Fotoğraf çekilemedi: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Ses kaydet ve text'e embed et
  Future<void> _toggleRecording() async {
    if (_recorder == null) return;

    if (_isRecording) {
      // Kaydı durdur
      final path = await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
        _recordingPath = path;
      });

      if (path != null) {
        await _saveAndEmbedAudioFile(path);
      }
    } else {
      // Kaydı başlat
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.aac';
      final filePath = '${appDir.path}/$fileName';

      await _recorder!.startRecorder(toFile: filePath, codec: Codec.aacADTS);

      setState(() {
        _isRecording = true;
      });
    }
  }

  // Renk seçici dialog
  void _showColorPicker() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Metin Rengi Seç'),
            content: Container(
              width: 300,
              height: 200,
              child: GridView.count(
                crossAxisCount: 6,
                children:
                    [
                          Colors.black,
                          Colors.red,
                          Colors.orange,
                          Colors.yellow,
                          Colors.green,
                          Colors.blue,
                          Colors.purple,
                          Colors.pink,
                          Colors.brown,
                          Colors.grey,
                          Colors.teal,
                          Colors.indigo,
                        ]
                        .map(
                          (color) => GestureDetector(
                            onTap: () {
                              // Basit renk ayarlama - hex değeri kullan
                              final hexColor =
                                  '#${color.value.toRadixString(16).padLeft(8, '0')}';
                              _quillController.formatSelection(
                                quill.Attribute.clone(
                                  quill.Attribute.color,
                                  hexColor,
                                ),
                              );
                              Navigator.pop(context);
                            },
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: const SizedBox.shrink(),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
            ],
          ),
    );
  }

  // El yazısı dialog ve embed
  void _toggleHandwritingMode() {
    setState(() {
      _isHandwritingMode = !_isHandwritingMode;
    });

    if (_isHandwritingMode) {
      _showHandwritingDialog();
    }
  }

  void _showHandwritingDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('El Yazısı Notu'),
            content: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Toolbar
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Spacer(),
                        // Geri al butonu
                        IconButton(
                          onPressed: () {
                            if (_signatureController.canUndo) {
                              _signatureController.undo();
                            }
                          },
                          icon: const Icon(Icons.undo),
                          tooltip: 'Geri Al',
                        ),
                        // İleri al butonu
                        IconButton(
                          onPressed: () {
                            if (_signatureController.canRedo) {
                              _signatureController.redo();
                            }
                          },
                          icon: const Icon(Icons.redo),
                          tooltip: 'İleri Al',
                        ),
                      ],
                    ),
                  ),
                  // Signature canvas
                  Expanded(
                    child: Signature(
                      key: _signatureKey,
                      controller: _signatureController,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _signatureController.clear();
                },
                child: const Text('Temizle'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _saveAndEmbedHandwriting();
                  Navigator.pop(context);
                },
                child: const Text('Kaydet'),
              ),
            ],
          ),
    );
  }

  // Helper methods for embedding content
  Future<void> _saveAndEmbedImageFile(File file, String fileName) async {
    final appDir = await getApplicationDocumentsDirectory();
    final savedFile = await file.copy('${appDir.path}/$fileName');

    final mediaFile = MediaFile(
      weekId: widget.week.id,
      fileName: fileName,
      filePath: savedFile.path,
      fileType: 'image',
    );

    await _mediaFileDao.insertMediaFile(mediaFile);
    await _loadMediaFiles();

    // Tıklanabilir görsel widget'ı ekle
    _insertFileEmbed(fileName, savedFile.path, 'image');

    Get.snackbar(
      'Başarılı',
      'Görsel eklendi',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  Future<void> _saveAndEmbedAudioFile(String path) async {
    final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.aac';

    final mediaFile = MediaFile(
      weekId: widget.week.id,
      fileName: fileName,
      filePath: path,
      fileType: 'audio',
    );

    await _mediaFileDao.insertMediaFile(mediaFile);
    await _loadMediaFiles();

    // Tıklanabilir ses widget'ı ekle
    _insertFileEmbed(fileName, path, 'audio');

    Get.snackbar(
      'Başarılı',
      'Ses kaydı eklendi',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  Future<void> _saveAndEmbedHandwriting() async {
    if (_signatureController.isEmpty) {
      Get.snackbar(
        'Uyarı',
        'Kaydedilecek el yazısı bulunamadı',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final signature = await _signatureController.toPngBytes();

    if (signature == null) {
      Get.snackbar(
        'Hata',
        'El yazısı PNG formatına dönüştürülemedi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // PNG'yi 180 derece döndür
    final originalImage = img.decodeImage(signature);
    final rotatedImage = img.copyRotate(originalImage!, angle: 180);
    final rotatedPng = img.encodePng(rotatedImage);

    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'handwriting_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File('${appDir.path}/$fileName');

    await file.writeAsBytes(rotatedPng);

    final mediaFile = MediaFile(
      weekId: widget.week.id,
      fileName: fileName,
      filePath: file.path,
      fileType: 'handwriting',
    );

    await _mediaFileDao.insertMediaFile(mediaFile);
    await _loadMediaFiles();

    // Tıklanabilir el yazısı widget'ı ekle
    _insertFileEmbed(fileName, file.path, 'handwriting');

    _signatureController.clear();

    Get.snackbar(
      'Başarılı',
      'El yazısı notu eklendi',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  // Tıklanabilir dosya embed'i ekleme
  void _insertFileEmbed(String fileName, String filePath, String fileType) {
    final index = _quillController.selection.baseOffset;

    // Custom embed data
    final embedData = {
      'fileName': fileName,
      'filePath': filePath,
      'fileType': fileType,
    };

    // Embed'i document'a ekle
    _quillController.document.insert(
      index,
      quill.BlockEmbed.custom(
        quill.CustomBlockEmbed('file', jsonEncode(embedData)),
      ),
    );

    // Cursor'u embed'den sonraya taşı
    _quillController.updateSelection(
      TextSelection.collapsed(offset: index + 1),
      quill.ChangeSource.local,
    );
  }

  void _removeFileEmbedFromQuill(String filePath) {
    _allowEmbedDelete = true;
    final doc = _quillController.document;
    final delta = doc.toDelta();
    final ops = delta.toList();
    int offset = 0;
    final targetName = filePath.split('/').last;
    for (final op in ops) {
      if (op.isInsert && op.data is Map) {
        final dataMap = op.data as Map;
        for (final key in dataMap.keys) {
          final embedDataRaw = dataMap[key];
          if (embedDataRaw == null) continue;
          final embedData =
              embedDataRaw is String ? jsonDecode(embedDataRaw) : embedDataRaw;
          final embedFilePath = embedData['filePath']?.toString() ?? '';
          final embedFileName = embedFilePath.split('/').last;
          if (embedFilePath == filePath || embedFileName == targetName) {
            doc.delete(offset, 1);
            // _lastEmbedFilePaths listesinden de çıkar
            _lastEmbedFilePaths.remove(filePath);
            _allowEmbedDelete = false;
            return;
          }
        }
      }
      offset += op.length as int;
    }
    _allowEmbedDelete = false;
  }

  Future<void> _deleteMedia(MediaFile media) async {
    // 1) Kullanıcıdan onay al
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Dosyayı sil?'),
            content: Text('"${media.fileName}" silinecek. Emin misin?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sil'),
              ),
            ],
          ),
    );

    if (shouldDelete != true) return;

    // 2) Quill embed’i sil
    _removeFileEmbedFromQuill(media.filePath);

    // 3) Veritabanından ve listeden sil
    await Get.find<WeekController>().deleteMediaFile(media, widget.week);
    await _loadMediaFiles();

    setState(() {});
  }

  Widget _buildCompactToolbarButton({
    required IconData icon,
    required VoidCallback? onPressed,
    String? tooltip,
    Color? iconColor,
    Color? backgroundColor,
    bool isSelected = false,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade100 : backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected
                    ? Colors.blue.shade300
                    : (backgroundColor != null
                        ? (iconColor ?? Colors.grey)
                        : Colors.transparent),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: IconButton(
          icon: Icon(
            icon,
            color: isSelected ? Colors.blue.shade700 : iconColor,
            size: 20,
          ),
          onPressed: onPressed,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  // Medya dosyalarını listele (örnek bir yerde, uygun yere ekle)
  Widget _buildMediaFileList() {
    return ListView.builder(
      key: const PageStorageKey('media_list'), // Listeye benzersiz key
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: widget.week.mediaFiles.length,
      itemBuilder: (context, index) {
        final media = widget.week.mediaFiles[index];
        return FileWidget(
          key: ValueKey('list_${media.id}'), // sabit ve benzersiz key
          media: media,
          week: widget.week,
          onDeleteMedia: _deleteMedia,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.week.title),
        backgroundColor: Color(AppConstants.primaryColorValue),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Obx(
            () => IconButton(
              icon: Icon(
                widget.week.isFavorite.value ? Icons.star : Icons.star_border,
                color:
                    widget.week.isFavorite.value ? Colors.amber : Colors.white,
              ),
              onPressed: () async {
                final controller = Get.find<SimpleController>();
                await controller.toggleFavorite(widget.week);
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              Get.back();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Kompakt Tek Satır Toolbar
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Temel formatlar
                  _buildCompactToolbarButton(
                    icon: Icons.color_lens_sharp,
                    onPressed: _showColorPicker,
                    tooltip: 'Renk',
                  ),
                  _buildCompactToolbarButton(
                    icon: Icons.format_bold,
                    onPressed:
                        () => _quillController.formatSelection(
                          quill.Attribute.bold,
                        ),
                    tooltip: 'Kalın',
                  ),
                  _buildCompactToolbarButton(
                    icon: Icons.format_italic,
                    onPressed:
                        () => _quillController.formatSelection(
                          quill.Attribute.italic,
                        ),
                    tooltip: 'İtalik',
                  ),
                  _buildCompactToolbarButton(
                    icon: Icons.format_underlined,
                    onPressed:
                        () => _quillController.formatSelection(
                          quill.Attribute.underline,
                        ),
                    tooltip: 'Altı çizili',
                  ),
                  _buildCompactToolbarButton(
                    icon: Icons.title,
                    onPressed:
                        () => _quillController.formatSelection(
                          quill.Attribute.h2,
                        ),
                    tooltip: 'Başlık',
                  ),
                  _buildCompactToolbarButton(
                    icon: Icons.format_list_bulleted,
                    onPressed:
                        () => _quillController.formatSelection(
                          quill.Attribute.ul,
                        ),
                    tooltip: 'Madde',
                  ),
                  _buildCompactToolbarButton(
                    icon: Icons.format_list_numbered,
                    onPressed:
                        () => _quillController.formatSelection(
                          quill.Attribute.ol,
                        ),
                    tooltip: 'Numara',
                  ),

                  // Separator
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.grey.shade300,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),

                  // Medya butonları
                  _buildCompactToolbarButton(
                    icon: Icons.description,
                    onPressed: _isLoading ? null : _pickDocumentFile,
                    tooltip: 'PDF/PPTX',
                    iconColor: Colors.orange,
                  ),
                  _buildCompactToolbarButton(
                    icon: Icons.image,
                    onPressed: _isLoading ? null : _pickImage,
                    tooltip: 'Görsel',
                    iconColor: Colors.blue,
                  ),
                  _buildCompactToolbarButton(
                    icon: Icons.camera_alt,
                    onPressed: _isLoading ? null : _takePhoto,
                    tooltip: 'Fotoğraf',
                    iconColor: Colors.green,
                  ),
                  _buildCompactToolbarButton(
                    icon: _isRecording ? Icons.stop : Icons.mic,
                    onPressed: _toggleRecording,
                    tooltip: _isRecording ? 'Durdur' : 'Ses Kaydet',
                    iconColor: Colors.red,
                    backgroundColor: _isRecording ? Colors.red.shade100 : null,
                  ),
                  _buildCompactToolbarButton(
                    icon: Icons.draw,
                    onPressed: _toggleHandwritingMode,
                    tooltip: 'El Yazısı',
                    iconColor: Colors.purple,
                    backgroundColor:
                        _isHandwritingMode ? Colors.purple.shade100 : null,
                  ),

                  // Undo/Redo
                  _buildCompactToolbarButton(
                    icon: Icons.undo,
                    onPressed: () => _quillController.undo(),
                    tooltip: 'Geri al',
                  ),
                  _buildCompactToolbarButton(
                    icon: Icons.redo,
                    onPressed: () => _quillController.redo(),
                    tooltip: 'Yinele',
                  ),

                  // Loading indicator
                  if (_isLoading)
                    Container(
                      width: 40,
                      height: 40,
                      padding: const EdgeInsets.all(8),
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
          ),

          // Ana yazı alanı - Tam ekran
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: quill.QuillEditor.basic(
                  controller: _quillController,
                  config: quill.QuillEditorConfig(
                    // Editör boşken kullanıcıya gösterilecek mesaj
                    placeholder: "Notlarınızı yazmaya başlayın...",
                    padding: EdgeInsets.all(16),
                    embedBuilders: [FileEmbedBuilder()],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _quillController.removeListener(_autoSaveContent);
    _quillController.dispose();
    _focusNode.dispose();
    _recorder?.closeRecorder();
    _signatureController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }
}

// Yardımcı fonksiyon: BoxFit.contain ile gösterilen resmin ekrandaki gerçek alanını hesapla
Rect calculateImageRect({
  required double imageWidth,
  required double imageHeight,
  required double widgetWidth,
  required double widgetHeight,
}) {
  final imageAspect = imageWidth / imageHeight;
  final widgetAspect = widgetWidth / widgetHeight;
  double shownWidth, shownHeight, offsetX, offsetY;
  if (imageAspect > widgetAspect) {
    shownWidth = widgetWidth;
    shownHeight = widgetWidth / imageAspect;
    offsetX = 0;
    offsetY = (widgetHeight - shownHeight) / 2;
  } else {
    shownHeight = widgetHeight;
    shownWidth = widgetHeight * imageAspect;
    offsetX = (widgetWidth - shownWidth) / 2;
    offsetY = 0;
  }
  return Rect.fromLTWH(offsetX, offsetY, shownWidth, shownHeight);
}

// Kamera ekranı
class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.cameras.first,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fotoğraf Çek'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final image = await _controller.takePicture();
            Get.back(result: File(image.path));
          } catch (e) {
            Get.snackbar('Hata', 'Fotoğraf çekilemedi: $e');
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _BackgroundDrawingPainter extends CustomPainter {
  final ui.Image image;
  _BackgroundDrawingPainter(this.image);
  @override
  void paint(Canvas canvas, Size size) {
    paintImage(
      canvas: canvas,
      rect: Offset.zero & size,
      image: image,
      fit: BoxFit.contain,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
