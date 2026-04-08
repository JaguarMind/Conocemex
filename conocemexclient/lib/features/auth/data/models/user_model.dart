import 'package:supabase_flutter/supabase_flutter.dart';

class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? profilePicture;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.profilePicture,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName:
          json['first_name'] as String? ?? json['firstName'] as String? ?? '',
      lastName:
          json['last_name'] as String? ?? json['lastName'] as String? ?? '',
      profilePicture:
          json['profile_picture'] as String? ??
          json['profilePicture'] as String?,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? json['createdAt'] as String,
      ),
    );
  }

  factory UserModel.fromSupabase(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      firstName:
          (metadata['first_name'] as String?) ??
          (metadata['firstName'] as String?) ??
          '',
      lastName:
          (metadata['last_name'] as String?) ??
          (metadata['lastName'] as String?) ??
          '',
      profilePicture:
          (metadata['profile_picture'] as String?) ??
          (metadata['avatar_url'] as String?) ??
          (metadata['avatarUrl'] as String?) ??
          user.userMetadata?['picture'] as String?,
      createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'profile_picture': profilePicture,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
