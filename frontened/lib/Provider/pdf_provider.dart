import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:frontened/services/pdf_service.dart';

class PdfProvider extends ChangeNotifier {
  File? _file;
  bool _isLoading = false;

  File? get file => _file;
  bool get isLoading => _isLoading;

  Future<void> openPDF(String courseId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _file = await PdfService.downloadPDF(courseId);
      if (_file != null) {
        await OpenFile.open(_file!.path);
      }
    } catch (e) {
      _file = null;
      debugPrint("OPEN ERROR: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}