import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:frontened/models/week_plan_model.dart';
import 'package:frontened/services/week_plan_service.dart';

class WeekPlanProvider with ChangeNotifier {
  WeekPlanModel? _plan;
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isUpdating = false;
  bool _isDeleting = false;
  bool _isGeneratingAI = false;
  bool _isGeneratingFromBook = false;
  bool _isDownloadingAI = false;
  final Map<int, bool> _downloadingWeeks = {};
  final Map<int, bool> _weekActionLoading = {};
  String? _error;

  WeekPlanModel? get plan => _plan;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  bool get isUpdating => _isUpdating;
  bool get isDeleting => _isDeleting;
  bool get isGeneratingAI => _isGeneratingAI;
  bool get isGeneratingFromBook => _isGeneratingFromBook;
  bool get isDownloadingAI => _isDownloadingAI;
  String? get error => _error;
  bool isWeekActionLoading(int weekNumber) => _weekActionLoading[weekNumber] ?? false;
  bool isWeekLoading(int weekNumber) => _downloadingWeeks[weekNumber] ?? false;

  void _setLoading(bool value) { _isLoading = value; notifyListeners(); }
  void clearError() { _error = null; notifyListeners(); }
  void clearPlan() { _plan = null; notifyListeners(); }

  Future<bool> createPlan(String courseId, List<WeekModel> weeks, {int semesterDuration = 18}) async {
    _isCreating = true; _error = null; notifyListeners();
    try {
      _plan = await WeekPlanService.createPlan(courseId, weeks, semesterDuration: semesterDuration);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll("Exception:", "").trim(); return false;
    } finally {
      _isCreating = false; notifyListeners();
    }
  }

  Future<void> fetchPlan(String courseId) async {
    _setLoading(true); _error = null;
    try {
      _plan = await WeekPlanService.getPlanByCourse(courseId);
    } catch (e) {
      _error = e.toString().replaceAll("Exception:", "").trim(); _plan = null;
    } finally { _setLoading(false); }
  }

  Future<bool> updatePlan(String planId, List<WeekModel> weeks) async {
    _isUpdating = true; _error = null; notifyListeners();
    try {
      _plan = await WeekPlanService.updatePlan(planId, weeks); return true;
    } catch (e) {
      _error = e.toString().replaceAll("Exception:", "").trim(); return false;
    } finally { _isUpdating = false; notifyListeners(); }
  }

  Future<bool> deletePlan(String planId) async {
    _isDeleting = true; _error = null; notifyListeners();
    try {
      await WeekPlanService.deletePlan(planId); _plan = null; return true;
    } catch (e) {
      _error = e.toString().replaceAll("Exception:", "").trim(); return false;
    } finally { _isDeleting = false; notifyListeners(); }
  }

  Future<bool> downloadAndOpenWeekPDF(String courseId, int weekNumber) async {
    _downloadingWeeks[weekNumber] = true; notifyListeners();
    try {
      final bytes = await WeekPlanService.downloadWeekPDF(courseId, weekNumber);
      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/week_${weekNumber}_course_$courseId.pdf");
      await file.writeAsBytes(bytes); await OpenFile.open(file.path); return true;
    } catch (e) {
      _error = e.toString().replaceAll("Exception:", "").trim(); return false;
    } finally { _downloadingWeeks[weekNumber] = false; notifyListeners(); }
  }

  // 🔥 Format Parameter added here
  Future<bool> generateAIPlan(String courseId, {required String courseTitle, String? prompt, required String format}) async {
    _isGeneratingAI = true; _error = null; notifyListeners();
    try {
      _plan = await WeekPlanService.generateAIPlan(courseId, courseTitle: courseTitle, prompt: prompt, format: format);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll("Exception:", "").trim(); return false;
    } finally { _isGeneratingAI = false; notifyListeners(); }
  }

  // 🔥 Format Parameter added here
  Future<bool> generateAIPlanFromBook(String courseId, {required String courseTitle, required File bookFile, required String format}) async {
    _isGeneratingFromBook = true; _error = null; notifyListeners();
    try {
      _plan = await WeekPlanService.generateAIPlanFromBook(courseId, courseTitle: courseTitle, bookFile: bookFile, format: format);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll("Exception:", "").trim(); return false;
    } finally { _isGeneratingFromBook = false; notifyListeners(); }
  }

  Future<bool> downloadAndOpenAIPlanPDF(String courseId) async {
    _isDownloadingAI = true; _error = null; notifyListeners();
    try {
      final bytes = await WeekPlanService.downloadAIPlanPDF(courseId);
      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/ai_plan_$courseId.pdf");
      await file.writeAsBytes(bytes); await OpenFile.open(file.path); return true;
    } catch (e) {
      _error = e.toString().replaceAll("Exception:", "").trim(); return false;
    } finally { _isDownloadingAI = false; notifyListeners(); }
  }

  Future<bool> updateWeekAI(String courseId, int weekNumber, {String? prompt}) async {
    _weekActionLoading[weekNumber] = true; notifyListeners();
    try {
      final updatedWeek = await WeekPlanService.updateWeekAI(courseId, weekNumber, prompt: prompt);
      if (_plan != null) {
        final index = _plan!.weeks.indexWhere((w) => w.weekNumber == weekNumber);
        if (index != -1) _plan!.weeks[index] = updatedWeek;
      }
      return true;
    } catch (e) {
      _error = e.toString().replaceAll("Exception:", "").trim(); return false;
    } finally { _weekActionLoading[weekNumber] = false; notifyListeners(); }
  }

  Future<bool> deleteWeek(String courseId, int weekNumber) async {
    _weekActionLoading[weekNumber] = true; notifyListeners();
    try {
      await WeekPlanService.deleteWeek(courseId, weekNumber);
      if (_plan != null) _plan!.weeks.removeWhere((w) => w.weekNumber == weekNumber);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll("Exception:", "").trim(); return false;
    } finally { _weekActionLoading[weekNumber] = false; notifyListeners(); }
  }
}