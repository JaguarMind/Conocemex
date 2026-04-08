import 'package:flutter/foundation.dart';

import '/features/offering/domain/entities/offering_entity.dart';
import '/features/offering/domain/usecases/create_offering_usecase.dart';
import '/features/offering/domain/usecases/get_offerings_usecase.dart';

class OfferingsViewModel extends ChangeNotifier {
  final GetOfferingsUseCase getOfferingsUseCase;
  final CreateOfferingUseCase createOfferingUseCase;

  OfferingsViewModel({
    required this.getOfferingsUseCase,
    required this.createOfferingUseCase,
  });

  List<OfferingEntity> _offerings = [];
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _error;

  List<OfferingEntity> get offerings => _offerings;
  bool get isLoading => _isLoading;
  bool get isSuccess => _isSuccess;
  String? get error => _error;

  Future<void> loadOfferings(String businessId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _offerings = await getOfferingsUseCase(businessId);
    } catch (e) {
      _error = 'Error al cargar productos/servicios: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createOffering({
    required String businessId,
    required String type,
    required String name,
    String? description,
    required double priceMxn,
    String priceType = 'fixed',
    int? durationMin,
    String? imageUrl,
  }) async {
    _isLoading = true;
    _isSuccess = false;
    _error = null;
    notifyListeners();

    try {
      await createOfferingUseCase(
        businessId: businessId,
        type: type,
        name: name,
        description: description,
        priceMxn: priceMxn,
        priceType: priceType,
        durationMin: durationMin,
        imageUrl: imageUrl,
      );
      _isSuccess = true;
      // Reload offerings
      _offerings = await getOfferingsUseCase(businessId);
    } catch (e) {
      _error = 'Error al crear producto/servicio: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  void reset() {
    _isSuccess = false;
    _error = null;
  }
}
