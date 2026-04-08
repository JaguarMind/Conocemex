import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/profile_entity.dart';

class ProfileModel {
  final String id;
  final String role;
  final String fullName;
  final String? avatarUrl;
  final String? nationality;
  final String? phone;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProfileModel({
    required this.id,
    required this.role,
    required this.fullName,
    required this.avatarUrl,
    required this.nationality,
    required this.phone,
    required this.onboardingCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      role: json['role'] as String? ?? 'turista',
      fullName:
          json['full_name'] as String? ?? json['fullName'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
      nationality: json['nationality'] as String?,
      phone: json['phone'] as String?,
      onboardingCompleted:
          json['onboarding_completed'] as bool? ??
          json['onboardingCompleted'] as bool? ??
          false,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? json['createdAt'] as String,
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] as String? ?? json['updatedAt'] as String,
      ),
    );
  }

  factory ProfileModel.fromSupabase(Map<String, dynamic> row) {
    return ProfileModel.fromJson(row);
  }

  factory ProfileModel.fromUserId(String id) {
    final now = DateTime.now();
    return ProfileModel(
      id: id,
      role: 'turista',
      fullName: '',
      avatarUrl: null,
      nationality: null,
      phone: null,
      onboardingCompleted: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory ProfileModel.fromSupabaseUser(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final fullName =
        (metadata['full_name'] as String?) ??
        (metadata['fullName'] as String?) ??
        (metadata['name'] as String?) ??
        '';

    return ProfileModel(
      id: user.id,
      role: (metadata['role'] as String?) ?? 'turista',
      fullName: fullName,
      avatarUrl:
          (metadata['avatar_url'] as String?) ??
          (metadata['avatarUrl'] as String?) ??
          (metadata['picture'] as String?) ??
          user.userMetadata?['avatar_url'] as String?,
      nationality: metadata['nationality'] as String?,
      phone: metadata['phone'] as String?,
      onboardingCompleted:
          metadata['onboarding_completed'] as bool? ??
          metadata['onboardingCompleted'] as bool? ??
          false,
      createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
    );
  }

  ProfileEntity toEntity() {
    return ProfileEntity(
      id: id,
      role: role,
      fullName: fullName,
      avatarUrl: avatarUrl,
      nationality: nationality,
      phone: phone,
      onboardingCompleted: onboardingCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'nationality': nationality,
      'phone': phone,
      'onboarding_completed': onboardingCompleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
