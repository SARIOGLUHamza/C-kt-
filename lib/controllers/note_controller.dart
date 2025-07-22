import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/colored_note.dart';
import 'package:flutter/material.dart';

class NoteController {
  final String pdfKey;
  NoteController(this.pdfKey);

  Future<List<ColoredNote>> loadNotes() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dataFile = File('${appDir.path}/precise_pdf_${pdfKey}.json');
      if (await dataFile.exists()) {
        final jsonString = await dataFile.readAsString();
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        final notes =
            (data['notes'] as List)
                .map((n) => ColoredNote.fromJson(n))
                .toList();
        return notes;
      }
    } catch (e) {
      debugPrint('❌ Not verileri yüklenirken hata: $e');
    }
    return [];
  }

  Future<void> saveNotes(List<ColoredNote> notes) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dataFile = File('${appDir.path}/precise_pdf_${pdfKey}.json');
      final data = {
        'notes': notes.map((n) => n.toJson()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await dataFile.writeAsString(jsonEncode(data));
      debugPrint('✅ Not verileri kaydedildi: ${dataFile.path}');
    } catch (e) {
      debugPrint('❌ Not verileri kaydedilirken hata: $e');
    }
  }
}
