import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:frontened/models/user_model.dart';
import 'package:frontened/services/auth_service.dart';
import 'package:frontened/services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  Future<bool> login(String email, String password, String role) async {
    _setLoading(true);
    _clearError();
    try {
      final authData = await ApiService.login(email, password, role);
      _user = authData.user;
      return true;
    } catch (e) {
      _error = e.toString().replaceAll("Exception:", "").trim();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signup({
    required String name, required String email, required String password, required String role,
    required String fatherName, required String cnic, required String department,
    String? rollNumber, String? semester, String? section,
    String? qualification, String? experience, String? speciality,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final authData = await ApiService.signup(
        name: name, email: email, password: password, role: role, 
        fatherName: fatherName, cnic: cnic, department: department,
        rollNumber: rollNumber, semester: semester, section: section, 
        qualification: qualification, experience: experience, speciality: speciality,
      );
      _user = authData.user;
      return true;
    } catch (e) {
      _error = e.toString().replaceAll("Exception:", "").trim();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 🔥 GOOGLE LOGIN PROVIDER METHOD (UPDATED WITH OPTIONAL EMAIL & NAME)
  Future<bool> googleLogin(String idToken, String role, {String? email, String? name}) async {
    _setLoading(true);
    _clearError();
    try {
      final authData = await ApiService.googleSignIn(idToken, role, email: email, name: name);
      _user = authData.user;
      return true;
    } catch (e) {
      _error = e.toString().replaceAll("Exception:", "").trim();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadProfile() async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) return;
    _setLoading(true);
    try {
      _user = await ApiService.getProfile();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data, {File? imageFile, File? profileImage}) async {
    _setLoading(true);
    _clearError();
    try {
      File? fileToUpload = imageFile ?? profileImage;
      _user = await ApiService.updateProfile(
        name: data['name'] ?? _user?.name ?? '',
        fatherName: data['fatherName'],
        cnic: data['cnic'],
        department: data['department'],
        rollNumber: data['rollNumber'],
        semester: data['semester'],
        section: data['section'],
        qualification: data['qualification'],
        experience: data['experience'],
        speciality: data['speciality'],
        profileImage: fileToUpload,
      );
      return true;
    } catch (e) {
      _error = e.toString().replaceAll("Exception:", "").trim();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();
    try {
      await ApiService.forgotPassword(email);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll("Exception:", "").trim();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyOTP(String email, String otp) async {
    _setLoading(true);
    _clearError();
    try {
      await ApiService.verifyOTP(email, otp);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll("Exception:", "").trim();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword({required String email, required String newPassword}) async {
    _setLoading(true);
    _clearError();
    try {
      await ApiService.resetPassword(email: email, newPassword: newPassword);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll("Exception:", "").trim();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await ApiService.logout();
    } catch (e) {
      debugPrint("Backend logout trace handled: $e");
    }

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
        await googleSignIn.disconnect();
      }
    } catch (googleErr) {
      debugPrint("Google SignOut error caught: $googleErr");
    }

    try {
      await StorageService.clearAll();
    } catch (e) {
      debugPrint("Local storage reset error: $e");
    }

    _user = null;
    _clearError();
    _setLoading(false);
  }
}