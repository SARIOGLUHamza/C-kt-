import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
//import 'package:get_storage/get_storage.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfPath;
  const PdfViewerScreen({super.key, required this.pdfPath});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  bool _isLoading = true;
  bool _fileExists = false;
  String _fileSize = '';
  String _fileName = '';

  @override
  void initState() {
    super.initState();
    _checkFile();
  }

  Future<void> _checkFile() async {
    try {
      final file = File(widget.pdfPath);
      _fileExists = await file.exists();

      if (_fileExists) {
        final size = await file.length();
        _fileSize = _formatFileSize(size);
        _fileName = widget.pdfPath.split('/').last;
      }
    } catch (e) {
      print('Dosya kontrol hatası: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _openWithExternalApp() async {
    try {
      final result = await OpenFile.open(widget.pdfPath);
      if (result.type != ResultType.done) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Dosya açılamadı: ${result.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _shareFile() async {
    // Dosya paylaşımı için basit bir dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Dosya Paylaş'),
            content: const Text('Bu özellik yakında eklenecek.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tamam'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('PDF Görüntüleyici'),
          backgroundColor: Colors.blue[800],
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Dosya kontrol ediliyor...'),
            ],
          ),
        ),
      );
    }

    if (!_fileExists) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('PDF Görüntüleyici'),
          backgroundColor: Colors.blue[800],
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 24),
                Text(
                  'Dosya Bulunamadı',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'PDF dosyası belirtilen konumda bulunamadı:\n${widget.pdfPath}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _checkFile(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar Dene'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Dosya bulunduysa PDFView ile göster
    return Scaffold(
      appBar: AppBar(
        title: Text(_fileName),
        backgroundColor: Colors.blue[800],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.open_in_new, color: Colors.white),
            onPressed: _openWithExternalApp,
            tooltip: 'Harici Uygulamada Aç',
          ),
        ],
      ),
      body: PDFView(
        filePath: widget.pdfPath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF yüklenirken hata: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
        onPageError: (page, error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sayfa $page yüklenirken hata: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      ),
    );
  }
}
