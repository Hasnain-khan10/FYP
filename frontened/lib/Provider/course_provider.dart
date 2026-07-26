import 'package:flutter/material.dart';
import 'package:frontened/models/course_model.dart';
import 'package:frontened/services/course_service.dart';

class CourseProvider with ChangeNotifier {
  List<CourseModel> _courses = [];
  CourseModel? _selectedCourse;
  List<dynamic> _courseStudents = [];

  bool _isStudentsLoading = false;
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isJoining = false;
  bool _isPreviewLoading = false;
  bool _isUpdating = false;
  bool _isDeleting = false;

  String? _error;
  String? _joinLink;

  List<CourseModel> get courses => _courses;
  CourseModel? get selectedCourse => _selectedCourse;
  List<dynamic> get courseStudents => _courseStudents;
  bool get isStudentsLoading => _isStudentsLoading;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  bool get isJoining => _isJoining;
  bool get isPreviewLoading => _isPreviewLoading;
  bool get isUpdating => _isUpdating;
  bool get isDeleting => _isDeleting;
  String? get error => _error;
  String? get joinLink => _joinLink;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> fetchCourses() async {
    _setLoading(true);
    _error = null;
    try {
      _courses = await CourseService.getCourses();
    } catch (e) {
      _error = e.toString().replaceAll("Exception:", "").trim();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchCourseById(String id) async {
    _setLoading(true);
    _error = null;
    try {
      _selectedCourse = await CourseService.getCourseById(id);
    } catch (e) {
      _error = e.toString().replaceAll("Exception:", "").trim();
    } finally {
      _setLoading(false);
    }
  }

  Future<CourseModel?> createCourse(CourseModel course) async {
    _isCreating = true;
    _error = null;
    _joinLink = null;
    notifyListeners();
    try {
      final result = await CourseService.createCourse(course);
      final newCourse = result["course"] as CourseModel;
      _joinLink = result["joinLink"];
      _courses.add(newCourse);
      _selectedCourse = newCourse;
      return newCourse;
    } catch (e) {
      _error = e.toString().replaceAll("Exception:", "").trim();
      return null;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  Future<bool> joinCourse(String joinCode) async {
    _isJoining = true;
    _error = null;
    notifyListeners();
    try {
      await CourseService.joinCourse(joinCode);
      await fetchCourses();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll("Exception:", "").trim();
      return false;
    } finally {
      _isJoining = false;
      notifyListeners();
    }
  }

  Future<void> fetchCourseStudents(String courseId) async {
    _isStudentsLoading = true;
    notifyListeners();
    try {
      _courseStudents = await CourseService.getCourseStudents(courseId);
    } catch (e) {
      _courseStudents = [];
    } finally {
      _isStudentsLoading = false;
      notifyListeners();
    }
  }

  Future<void> previewCourse(String code) async {
    _isPreviewLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedCourse = await CourseService.previewCourse(code);
    } catch (e) {
      _error = e.toString().replaceAll("Exception:", "").trim();
      _selectedCourse = null;
    } finally {
      _isPreviewLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateCourse(String id, CourseModel course) async {
    _isUpdating = true;
    _error = null;
    notifyListeners();
    try {
      final updatedCourse = await CourseService.updateCourse(id, course);
      final index = _courses.indexWhere((c) => c.id == id);
      if (index != -1) _courses[index] = updatedCourse;
      if (_selectedCourse?.id == id) _selectedCourse = updatedCourse;
      return true;
    } catch (e) {
      _error = e.toString().replaceAll("Exception:", "").trim();
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCourse(String id) async {
    _isDeleting = true;
    _error = null;
    notifyListeners();
    try {
      await CourseService.deleteCourse(id);
      _courses.removeWhere((c) => c.id == id);
      if (_selectedCourse?.id == id) _selectedCourse = null;
      return true;
    } catch (e) {
      _error = e.toString().replaceAll("Exception:", "").trim();
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }
}