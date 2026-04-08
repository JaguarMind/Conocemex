import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final String id;
  final String slug;
  final String? icon;
  final int sortOrder;
  final String name;
  final String? description;

  const CategoryEntity({
    required this.id,
    required this.slug,
    this.icon,
    required this.sortOrder,
    required this.name,
    this.description,
  });

  @override
  List<Object?> get props => [id, slug, icon, sortOrder, name, description];
}
