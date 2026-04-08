import 'package:supabase_flutter/supabase_flutter.dart';

import 'user_model.dart';

class AuthResponseModel {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken:
          json['access_token'] as String? ?? json['accessToken'] as String,
      refreshToken:
          json['refresh_token'] as String? ?? json['refreshToken'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  factory AuthResponseModel.fromSupabase(Session session) {
    return AuthResponseModel(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken ?? '',
      user: UserModel.fromSupabase(session.user),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'user': user.toJson(),
    };
  }
}
