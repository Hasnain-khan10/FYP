import 'user_model.dart';

class AuthModel {
  final String token;
  final UserModel user;

  AuthModel({
    required this.token,
    required this.user,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      token: json['token'] ?? "",
      user: UserModel.fromJson(json['user'] ?? {}),
    );
  }
}