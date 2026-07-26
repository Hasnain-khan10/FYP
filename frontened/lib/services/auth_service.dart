import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:frontened/core/api.dart';
import 'package:frontened/models/user_model.dart';
import 'package:frontened/models/auth_models.dart';
import 'package:frontened/services/storage_service.dart';

class ApiService {

  // ================= LOGIN =================
  static Future<AuthModel> login(String email, String password, String role) async {
    String? fcmToken;
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      fcmToken = "";
    }

    final response = await http.post(
      Uri.parse("${Api.baseUrl}/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
        "role": role,
        "fcmToken": fcmToken ?? "" 
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final auth = AuthModel.fromJson(data);
      await StorageService.saveToken(auth.token);
      await StorageService.saveRole(auth.user.role);
      return auth;
    } else {
      throw Exception(data["message"] ?? data["detail"] ?? "Login failed");
    }
  }

  // ================= SIGNUP =================
  static Future<AuthModel> signup({
    required String name, required String email, required String password, required String role,
    String? fatherName, String? cnic, String? department,
    String? rollNumber, String? semester, String? section,
    String? qualification, String? experience, String? speciality,
  }) async {
    String? fcmToken;
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      fcmToken = "";
    }

    final Map<String, dynamic> body = {
      "name": name, 
      "email": email, 
      "password": password, 
      "role": role,
      "fatherName": fatherName ?? "", 
      "cnic": cnic ?? "", 
      "department": department ?? "",
      "fcmToken": fcmToken ?? "",
      "rollNumber": rollNumber ?? "", 
      "semester": semester ?? "", 
      "section": section ?? "",
      "qualification": qualification ?? "", 
      "experience": experience ?? "", 
      "speciality": speciality ?? "",
    };

    final response = await http.post(
      Uri.parse("${Api.baseUrl}/auth/signup"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201 || response.statusCode == 200) {
      final auth = AuthModel.fromJson(data);
      await StorageService.saveToken(auth.token);
      await StorageService.saveRole(auth.user.role);
      return auth;
    } else {
      throw Exception(data["message"] ?? data["detail"] ?? "Signup failed");
    }
  }

  // ================= PROFILE =================
  static Future<UserModel> getProfile() async {
    final token = await StorageService.getToken();
    final response = await http.get(
      Uri.parse("${Api.baseUrl}/auth/profile"),
      headers: {"Authorization": "Bearer $token"},
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return UserModel.fromJson(data["user"] ?? data);
    } else {
      throw Exception("Failed to load profile");
    }
  }

  // ================= UPDATE PROFILE (MULTIPART) =================
  static Future<UserModel> updateProfile({
    required String name, String? fatherName, String? cnic, String? department,
    String? rollNumber, String? semester, String? section,
    String? qualification, String? experience, String? speciality,
    File? profileImage,
  }) async {
    final token = await StorageService.getToken();
    final request = http.MultipartRequest("PUT", Uri.parse("${Api.baseUrl}/auth/profile"));
    request.headers["Authorization"] = "Bearer $token";

    request.fields["name"] = name;
    if (fatherName != null) request.fields["fatherName"] = fatherName;
    if (cnic != null) request.fields["cnic"] = cnic;
    if (department != null) request.fields["department"] = department;
    if (rollNumber != null) request.fields["rollNumber"] = rollNumber;
    if (semester != null) request.fields["semester"] = semester;
    if (section != null) request.fields["section"] = section;
    if (qualification != null) request.fields["qualification"] = qualification;
    if (experience != null) request.fields["experience"] = experience;
    if (speciality != null) request.fields["speciality"] = speciality;

    String? fcmToken;
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) request.fields["fcmToken"] = fcmToken;
    } catch (_) {}

    if (profileImage != null) {
      request.files.add(await http.MultipartFile.fromPath("profileImage", profileImage.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return UserModel.fromJson(data["user"]);
    } else {
      throw Exception(data["message"] ?? "Failed to update profile");
    }
  }

  // ================= PASSWORD CONTROLS =================
  static Future<void> logout() async {
    await StorageService.clearAll();
  }

  static Future<String> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse("${Api.baseUrl}/auth/forgot-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data["message"] ?? "OTP sent";
    throw Exception(data["message"] ?? data["detail"] ?? "Something went wrong");
  }

  static Future<String> verifyOTP(String email, String otp) async {
    final response = await http.post(
      Uri.parse("${Api.baseUrl}/auth/verify-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "otp": otp}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data["message"] ?? "OTP verified";
    throw Exception(data["message"] ?? data["detail"] ?? "Invalid OTP");
  }

  static Future<String> resetPassword({required String email, required String newPassword}) async {
    final response = await http.post(
      Uri.parse("${Api.baseUrl}/auth/reset-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "newPassword": newPassword}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data["message"] ?? "Password reset successful";
    throw Exception(data["message"] ?? data["detail"] ?? "Password reset failed");
  }

  // 🔥 GOOGLE SIGN IN METHOD (WITH EMAIL & NAME PARAMETERS)
  static Future<AuthModel> googleSignIn(String idToken, String role, {String? email, String? name}) async {
    String? fcmToken;
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
    } catch (_) {}

    final response = await http.post(
      Uri.parse("${Api.baseUrl}/auth/google-login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "idToken": idToken,
        "role": role,
        "email": email ?? "",
        "name": name ?? "",
        "fcmToken": fcmToken ?? ""
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final auth = AuthModel.fromJson(data);
      await StorageService.saveToken(auth.token);
      await StorageService.saveRole(auth.user.role);
      return auth;
    } else {
      throw Exception(data["message"] ?? data["detail"] ?? "Google login failed");
    }
  }
}