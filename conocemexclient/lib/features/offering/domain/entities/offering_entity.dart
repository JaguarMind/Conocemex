import 'package:equatable/equatable.dart';

class OfferingEntity extends Equatable {
  final String id;
  final String businessId;
  final String type; // 'product' | 'service'
  final double priceMxn;
  final String priceType; // 'fixed' | 'from' | 'hourly' | 'per_person' | 'quote'
  final int? durationMin;
  final String? imageUrl;
  final bool isActive;
  final String name;
  final String? description;
  final DateTime createdAt;

  const OfferingEntity({
    required this.id,
    required this.businessId,
    required this.type,
    required this.priceMxn,
    required this.priceType,
    this.durationMin,
    this.imageUrl,
    required this.isActive,
    required this.name,
    this.description,
    required this.createdAt,
  });

  String get typeLabel => type == 'product' ? 'Producto' : 'Servicio';

  String get priceLabel {
    final price = '\$${priceMxn.toStringAsFixed(2)} MXN';
    switch (priceType) {
      case 'from':
        return 'Desde $price';
      case 'hourly':
        return '$price/hr';
      case 'per_person':
        return '$price/persona';
      case 'quote':
        return 'Cotizar';
      default:
        return price;
    }
  }

  @override
  List<Object?> get props => [id];
}
