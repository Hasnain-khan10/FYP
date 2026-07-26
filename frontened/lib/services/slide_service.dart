import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontened/core/api.dart';
import 'package:frontened/services/storage_service.dart';
import 'package:frontened/models/slide_model.dart';

class SlideService {
  static Future<Map<String, String>> _headers() async {
    final token = await StorageService.getToken();
    return {"Content-Type": "application/json", "Authorization": "Bearer $token"};
  }

  static Future<SlideModel> generateSlides(String courseId, String topic) async {
    final response = await http.post(Uri.parse("${Api.baseUrl}/slides"), headers: await _headers(), body: jsonEncode({"courseId": courseId, "topic": topic}));
    if (response.statusCode == 201) return SlideModel.fromJson(jsonDecode(response.body)["slideDoc"]);
    throw Exception(jsonDecode(response.body)["message"] ?? "Failed to generate slides");
  }

  static Future<List<SlideModel>> getSlidesByCourse(String courseId) async {
    final response = await http.get(Uri.parse("${Api.baseUrl}/slides/$courseId"), headers: await _headers());
    if (response.statusCode == 200) return List<SlideModel>.from(jsonDecode(response.body).map((s) => SlideModel.fromJson(s)));
    throw Exception("Failed to fetch slides");
  }

  static Future<String> exportSlidesToPPT(String slideId) async {
    final response = await http.post(Uri.parse("${Api.baseUrl}/slides/export/$slideId"), headers: await _headers());
    if (response.statusCode == 200) return jsonDecode(response.body)["pptUrl"];
    throw Exception(jsonDecode(response.body)["message"] ?? "PPT export failed");
  }

  static Future<SlideModel> updateSlides(String id, List<SlideItem> slides) async {
    final response = await http.put(Uri.parse("${Api.baseUrl}/slides/$id"), headers: await _headers(), body: jsonEncode({"slides": slides.map((s) => s.toJson()).toList()}));
    if (response.statusCode == 200) return SlideModel.fromJson(jsonDecode(response.body)["slide"]);
    throw Exception(jsonDecode(response.body)["message"] ?? "Update failed");
  }

  static Future<void> deleteSlides(String id) async {
    final response = await http.delete(Uri.parse("${Api.baseUrl}/slides/$id"), headers: await _headers());
    if (response.statusCode != 200) throw Exception(jsonDecode(response.body)["message"] ?? "Delete failed");
  }
}