import 'package:flutter/foundation.dart';

import '/features/business/domain/usecases/create_business_usecase.dart';
import '/features/category/domain/entities/category_entity.dart';
import '/features/category/domain/usecases/get_categories_usecase.dart';

class CreateBusinessViewModel extends ChangeNotifier {
  final CreateBusinessUseCase createBusinessUseCase;
  final GetCategoriesUseCase getCategoriesUseCase;

  CreateBusinessViewModel({
    required this.createBusinessUseCase,
    required this.getCategoriesUseCase,
  });

  List<CategoryEntity> _categories = [];
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _error;

  List<CategoryEntity> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isSuccess => _isSuccess;
  String? get error => _error;

  Future<void> loadCategories() async {
    try {
      _categories = await getCategoriesUseCase();
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar categorias: $e';
      notifyListeners();
    }
  }

  Future<void> createBusiness({
    required String name,
    required String categoryId,
    String? phone,
    String? address,
    required double latitude,
    required double longitude,
    String? coverImageUrl,
  }) async {
    _isLoading = true;
    _isSuccess = false;
    _error = null;
    notifyListeners();

    try {
      await createBusinessUseCase(
        name: name,
        categoryId: categoryId,
        phone: phone,
        address: address,
        latitude: latitude,
        longitude: longitude,
        coverImageUrl: coverImageUrl,
      );
      _isSuccess = true;
    } catch (e) {
      _error = 'Error al crear negocio: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  void reset() {
    _isSuccess = false;
    _error = null;
  }
}
