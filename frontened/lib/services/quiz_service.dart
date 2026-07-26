import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:frontened/core/api.dart';
import 'package:frontened/services/storage_service.dart';
import 'package:frontened/models/Quiz/quiz_model.dart';

class QuizService {
  Future<Map<String, String>> _headers() async {
    final token = await StorageService.getToken();
    return {"Content-Type": "application/json", "Authorization": "Bearer $token", "Accept": "application/json"};
  }

  Future<Map<String, String>> _multipartHeaders() async {
    final token = await StorageService.getToken();
    return {"Authorization": "Bearer $token", "Accept": "application/json"};
  }

  Future<List<Quiz>> getAllQuizzes() async {
    final response = await http.get(Uri.parse("${Api.baseUrl}/quizzes"), headers: await _headers());
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      List quizList = data['quizzes'] ?? (data is List ? data : []);
      return quizList.map((q) => Quiz.fromJson(q is Map<String, dynamic> ? q : Map<String, dynamic>.from(q))).toList();
    }
    throw Exception(data['message'] ?? "Failed to fetch quizzes");
  }

  Future<List<Quiz>> getQuizzesByCourse(String courseId) async {
    final response = await http.get(Uri.parse("${Api.baseUrl}/quizzes/course/$courseId"), headers: await _headers());
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      List quizList = data['quizzes'] ?? (data is List ? data : []);
      return quizList.map((q) => Quiz.fromJson(q is Map<String, dynamic> ? q : Map<String, dynamic>.from(q))).toList();
    }
    throw Exception(data['message'] ?? "Failed to fetch course quizzes");
  }

  Future<Map<String, dynamic>> getTeacherQuizResults({required String quizId}) async {
    final response = await http.get(Uri.parse("${Api.baseUrl}/quizzes/results/$quizId"), headers: await _headers());
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? "Failed to fetch results");
  }

  Future<bool> updateManualMarks({required String attemptId, required int manualScore, int? questionIndex}) async {
    final response = await http.put(
      Uri.parse("${Api.baseUrl}/quizzes/manual-score/$attemptId"),
      headers: await _headers(),
      body: jsonEncode({"manualScore": manualScore, "questionIndex": questionIndex}),
    );
    return response.statusCode == 200;
  }

  Future<bool> createQuiz({
    required String courseId, required String title, required String type,
    List? questions, List? shortQuestions, List? longQuestions,
    String? openDateTime, String? deadlineDateTime,
  }) async {
    int total = 0;
    if (questions != null) for(var q in questions) {
      total += (int.tryParse(q['marks'].toString()) ?? 1);
    }
    if (shortQuestions != null) for(var q in shortQuestions) {
      total += (int.tryParse(q['marks'].toString()) ?? 5);
    }
    if (longQuestions != null) for(var q in longQuestions) {
      total += (int.tryParse(q['marks'].toString()) ?? 5);
    }

    final parsedCourseId = int.tryParse(courseId) ?? 0;

    final response = await http.post(
        Uri.parse("${Api.baseUrl}/quizzes"),
        headers: await _headers(),
        body: jsonEncode({
          "courseId": parsedCourseId, 
          "title": title, 
          "type": type,
          "questions": questions ?? [], 
          "shortQuestions": shortQuestions ?? [], 
          "longQuestions": longQuestions ?? [],
          "totalMarks": total,
          "openDateTime": openDateTime,
          "deadlineDateTime": deadlineDateTime,
        })
    );
    return response.statusCode == 201 || response.statusCode == 200;
  }

  Future<Map<String, dynamic>> attemptQuiz({required String quizId, required List answers}) async {
    final response = await http.post(Uri.parse("${Api.baseUrl}/quizzes/attempt/$quizId"), headers: await _headers(), body: jsonEncode({"answers": answers}));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? "Failed to submit attempt");
  }

  Future<Map<String, dynamic>> scanAIQuizMarks({
    required String courseId, required String studentId, required String title, required String quizId,
    required List<File> files, int? questionIndex, String? questionText, int? maxMarks
  }) async {
    final request = http.MultipartRequest("POST", Uri.parse("${Api.baseUrl}/quizzes/scan-ai-marks"));
    request.headers.addAll(await _multipartHeaders());
    request.fields['courseId'] = courseId; request.fields['studentId'] = studentId;
    request.fields['title'] = title; request.fields['quizId'] = quizId;

    if (questionIndex != null) request.fields['questionIndex'] = questionIndex.toString();
    if (questionText != null) request.fields['questionText'] = questionText;
    if (maxMarks != null) request.fields['maxMarks'] = maxMarks.toString();

    for (var file in files) {
      request.files.add(await http.MultipartFile.fromPath('files', file.path));
    }
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode != 200) throw Exception("Backend Error (${response.statusCode}): ${response.body}");
    return jsonDecode(response.body);
  }

  Future<bool> updateQuiz({
    required String quizId, String? title, List? questions, List? shortQuestions, List? longQuestions,
    String? openDateTime, String? deadlineDateTime,
  }) async {
    final response = await http.put(Uri.parse("${Api.baseUrl}/quizzes/$quizId"), headers: await _headers(), body: jsonEncode({
      if (title != null) "title": title,
      if (questions != null) "questions": questions,
      if (shortQuestions != null) "shortQuestions": shortQuestions,
      if (longQuestions != null) "longQuestions": longQuestions,
      if (openDateTime != null) "openDateTime": openDateTime,
      if (deadlineDateTime != null) "deadlineDateTime": deadlineDateTime,
    }));
    return response.statusCode == 200;
  }

  Future<bool> deleteQuiz(String quizId) async {
    final response = await http.delete(Uri.parse("${Api.baseUrl}/quizzes/$quizId"), headers: await _headers());
    return response.statusCode == 200;
  }

  Future<String?> generateAIQuestionQuizPdf({required String quizId}) async {
    final response = await http.get(Uri.parse("${Api.baseUrl}/quizzes/pdf/$quizId"), headers: await _headers());
    if (response.statusCode == 200) {
      final dir = await getTemporaryDirectory(); final file = File('${dir.path}/ai_exam_$quizId.pdf');
      await file.writeAsBytes(response.bodyBytes); return file.path;
    }
    return null;
  }

  Future<String?> generateQuestionQuizPDF({required String quizId, required String courseId, String? title}) async {
    final response = await http.get(Uri.parse("${Api.baseUrl}/quizzes/pdf/$quizId"), headers: await _headers());
    if (response.statusCode == 200) {
      final dir = await getTemporaryDirectory(); final file = File('${dir.path}/exam_$quizId.pdf');
      await file.writeAsBytes(response.bodyBytes); return file.path;
    }
    return null;
  }

  Future<Map<String, dynamic>> createAIMCQQuiz({
    required String courseId, required String prompt, required String difficulty,
    required int questionCount, required int marksPerQuestion, File? file,
    String? openDateTime, String? deadlineDateTime,
  }) async {
    final url = Uri.parse("${Api.baseUrl}/ai/quizzes/mcq");
    if (file != null && file.path.isNotEmpty) {
      final req = http.MultipartRequest("POST", url)..headers.addAll(await _multipartHeaders());
      req.fields.addAll({"courseId": courseId, "course": courseId, "topic": prompt, "prompt": prompt, "difficulty": difficulty, "questionCount": questionCount.toString(), "marksPerQuestion": marksPerQuestion.toString()});
      if(openDateTime != null) req.fields['openDateTime'] = openDateTime;
      if(deadlineDateTime != null) req.fields['deadlineDateTime'] = deadlineDateTime;
      req.files.add(await http.MultipartFile.fromPath("book", file.path));
      final streamedResponse = await req.send().timeout(const Duration(seconds: 90));
      final res = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) return data;
      throw Exception(data['message'] ?? "AI Generation Failed");
    } else {
      final res = await http.post(url, headers: await _headers(), body: jsonEncode({
        "courseId": courseId, "course": courseId, "topic": prompt, "prompt": prompt, "difficulty": difficulty, "questionCount": questionCount, "marksPerQuestion": marksPerQuestion,
        "openDateTime": openDateTime, "deadlineDateTime": deadlineDateTime,
      })).timeout(const Duration(seconds: 90));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) return data;
      throw Exception(data['message'] ?? "AI Generation Failed");
    }
  }

  Future<Map<String, dynamic>> createAIQuestionQuiz({
    required String courseId, required String prompt, required String difficulty, required String type, File? file,
    int? shortCount, int? shortMarks, int? shortEachMark, int? longCount, int? longMarks, int? longEachMark,
    String? openDateTime, String? deadlineDateTime,
  }) async {
    final url = Uri.parse("${Api.baseUrl}/ai/quizzes/descriptive");
    if (file != null && file.path.isNotEmpty) {
      final req = http.MultipartRequest("POST", url)..headers.addAll(await _multipartHeaders());
      req.fields.addAll({"courseId": courseId, "course": courseId, "topic": prompt, "prompt": prompt, "difficulty": difficulty, "type": type, "shortCount": (shortCount ?? 0).toString(), "shortEachMark": (shortEachMark ?? 2).toString(), "longCount": (longCount ?? 0).toString(), "longEachMark": (longEachMark ?? 5).toString()});
      if(openDateTime != null) req.fields['openDateTime'] = openDateTime;
      if(deadlineDateTime != null) req.fields['deadlineDateTime'] = deadlineDateTime;
      req.files.add(await http.MultipartFile.fromPath("book", file.path));
      final streamedResponse = await req.send().timeout(const Duration(seconds: 90));
      final res = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) return data;
      throw Exception(data['message'] ?? "AI Written Exam Generation Failed");
    } else {
      final res = await http.post(url, headers: await _headers(), body: jsonEncode({
        "courseId": courseId, "course": courseId, "topic": prompt, "prompt": prompt, "difficulty": difficulty, "type": type, "shortCount": shortCount ?? 0, "shortEachMark": shortEachMark ?? 2, "longCount": longCount ?? 0, "longEachMark": longEachMark ?? 5,
        "openDateTime": openDateTime, "deadlineDateTime": deadlineDateTime,
      })).timeout(const Duration(seconds: 90));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) return data;
      throw Exception(data['message'] ?? "AI Written Exam Generation Failed");
    }
  }
}