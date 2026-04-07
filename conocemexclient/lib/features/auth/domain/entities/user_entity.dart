import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? profilePicture;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.profilePicture,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    firstName,
    lastName,
    profilePicture,
    createdAt,
  ];
}
