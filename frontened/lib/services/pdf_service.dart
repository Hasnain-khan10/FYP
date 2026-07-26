import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:frontened/core/api.dart';
import 'package:frontened/services/storage_service.dart';

class PdfService {
  static Future<File?> downloadPDF(String courseId) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.get(Uri.parse("${Api.baseUrl}/pdf/course/$courseId"), headers: {"Authorization": "Bearer $token"});
      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File("${dir.path}/course_outline_$courseId.pdf");
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}