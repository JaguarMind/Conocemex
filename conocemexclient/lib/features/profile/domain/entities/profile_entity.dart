import 'package:equatable/equatable.dart';

class ProfileEntity extends Equatable {
  final String id;
  final String role;
  final String fullName;
  final String? avatarUrl;
  final String? nationality;
  final String? phone;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfileEntity({
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

  @override
  List<Object?> get props => [
    id,
    role,
    fullName,
    avatarUrl,
    nationality,
    phone,
    onboardingCompleted,
    createdAt,
    updatedAt,
  ];
}
