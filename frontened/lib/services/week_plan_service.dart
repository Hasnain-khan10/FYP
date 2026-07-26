import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:frontened/core/api.dart';
import 'package:frontened/services/storage_service.dart';
import 'package:frontened/models/week_plan_model.dart';

class WeekPlanService {
  static Future<Map<String, String>> _headers() async {
    final token = await StorageService.getToken();
    return {"Content-Type": "application/json", "Authorization": "Bearer $token", "Accept": "application/json"};
  }

  static Future<Map<String, String>> _authOnlyHeaders() async {
    final token = await StorageService.getToken();
    return {"Authorization": "Bearer $token", "Accept": "application/json"};
  }

  static Future<WeekPlanModel> createPlan(String courseId, List<WeekModel> weeks, {int semesterDuration = 18}) async {
    final response = await http.post(Uri.parse("${Api.baseUrl}/plans"), headers: await _headers(), body: jsonEncode({"courseId": courseId, "semesterDuration": semesterDuration, "weeks": weeks.map((e) => e.toJson()).toList()}));
    final data = jsonDecode(response.body);
    if (response.statusCode == 201 && data["plan"] != null) return WeekPlanModel.fromJson(data["plan"]);
    throw Exception(data["message"] ?? "Failed to create plan");
  }

  static Future<WeekPlanModel> getPlanByCourse(String courseId) async {
    final response = await http.get(Uri.parse("${Api.baseUrl}/plans/$courseId"), headers: await _headers());
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data["plan"] != null) return WeekPlanModel.fromJson(data["plan"]);
    throw Exception(data["message"] ?? "Plan not found");
  }

  static Future<WeekPlanModel> updatePlan(String planId, List<WeekModel> weeks) async {
    final response = await http.put(Uri.parse("${Api.baseUrl}/plans/$planId"), headers: await _headers(), body: jsonEncode({"weeks": weeks.map((e) => e.toJson()).toList()}));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data["plan"] != null) return WeekPlanModel.fromJson(data["plan"]);
    throw Exception(data["message"] ?? "Update failed");
  }

  static Future<void> deletePlan(String planId) async {
    final response = await http.delete(Uri.parse("${Api.baseUrl}/plans/$planId"), headers: await _headers());
    if (response.statusCode != 200) throw Exception(jsonDecode(response.body)["message"] ?? "Delete failed");
  }

  static Future<Uint8List> downloadWeekPDF(String courseId, int weekNumber) async {
    final response = await http.get(Uri.parse("${Api.baseUrl}/plans/pdf/week/$courseId/$weekNumber"), headers: await _headers());
    if (response.statusCode == 200) return response.bodyBytes;
    throw Exception(jsonDecode(response.body)["message"] ?? "Week PDF download failed");
  }

  // 🔥 ADDED TIMEOUT FOR HIGH DETAIL AI GENERATION (90 SECONDS)
  static Future<WeekPlanModel> generateAIPlan(String courseId, {required String courseTitle, String? prompt, required String format}) async {
    String combinedTopic = (prompt == null || prompt.isEmpty) ? courseTitle : "$courseTitle - $prompt";

    final response = await http.post(
      Uri.parse("${Api.baseUrl}/ai/plans"),
      headers: await _headers(),
      body: jsonEncode({
        "course": courseId, "courseId": courseId,
        "teacher": "6a2b27ef72643f1a4b2e7b2f", "teacherId": "6a2b27ef72643f1a4b2e7b2f",
        "topic": combinedTopic, "level": "university", "focus": "theory + practical",
        "style": "detailed academic syllabus", "teacherCustomPrompt": combinedTopic, "bookText": "",
        "format": format
      }),
    ).timeout(const Duration(seconds: 90)); // Prevents Socket Exception Crash

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data["success"] == true) return WeekPlanModel.fromJson(data["plan"]);
    throw Exception(data["message"] ?? "AI plan generation failed");
  }

  // 🔥 ADDED TIMEOUT FOR HEAVY PDF EXTRACTION
  static Future<WeekPlanModel> generateAIPlanFromBook(String courseId, {required String courseTitle, required File bookFile, required String format}) async {
    final request = http.MultipartRequest("POST", Uri.parse("${Api.baseUrl}/ai/plans"));
    request.headers.addAll(await _authOnlyHeaders());

    request.fields["course"] = courseId; request.fields["courseId"] = courseId;
    request.fields["teacher"] = "6a2b27ef72643f1a4b2e7b2f"; request.fields["teacherId"] = "6a2b27ef72643f1a4b2e7b2f";
    request.fields["topic"] = courseTitle;
    request.fields["level"] = "university";
    request.fields["focus"] = "theory + practical";
    request.fields["style"] = "detailed academic syllabus";
    request.fields["teacherCustomPrompt"] = "Extract highly detailed syllabus strictly matching: $courseTitle";
    request.fields["bookText"] = courseTitle;
    request.fields["format"] = format;

    request.files.add(await http.MultipartFile.fromPath("book", bookFile.path));

    final streamedResponse = await request.send().timeout(const Duration(seconds: 90));
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data["success"] == true) return WeekPlanModel.fromJson(data["plan"]);
    throw Exception(data["message"] ?? "Book AI generation failed");
  }

  static Future<Uint8List> downloadAIPlanPDF(String courseId) async {
    final response = await http.get(Uri.parse("${Api.baseUrl}/plans/ai/pdf/$courseId"), headers: await _headers());
    if (response.statusCode == 200) return response.bodyBytes;
    throw Exception(jsonDecode(response.body)["message"] ?? "AI full PDF download failed");
  }

  static Future<WeekModel> updateWeekAI(String courseId, int weekNumber, {String? prompt}) async {
    final response = await http.put(Uri.parse("${Api.baseUrl}/plans/week/update-ai"), headers: await _headers(), body: jsonEncode({"courseId": courseId, "weekNumber": weekNumber, "prompt": prompt ?? ""}));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data["week"] != null) return WeekModel.fromJson(data["week"]);
    throw Exception(data["message"] ?? "Week AI update failed");
  }

  static Future<void> deleteWeek(String courseId, int weekNumber) async {
    final response = await http.delete(Uri.parse("${Api.baseUrl}/plans/week/delete/$courseId/$weekNumber"), headers: await _headers());
    if (response.statusCode != 200) throw Exception("Week delete failed");
  }
}