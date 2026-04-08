import 'package:equatable/equatable.dart';

class BusinessEntity extends Equatable {
  final String id;
  final String ownerId;
  final String categoryId;
  final String name;
  final String? phone;
  final String? address;
  final double latitude;
  final double longitude;
  final String? coverImageUrl;
  final bool isVerified;
  final bool isActive;
  final int totalVisits;
  final double? averageRating;
  final String? categoryName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BusinessEntity({
    required this.id,
    required this.ownerId,
    required this.categoryId,
    required this.name,
    this.phone,
    this.address,
    required this.latitude,
    required this.longitude,
    this.coverImageUrl,
    required this.isVerified,
    required this.isActive,
    required this.totalVisits,
    this.averageRating,
    this.categoryName,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id];
}
