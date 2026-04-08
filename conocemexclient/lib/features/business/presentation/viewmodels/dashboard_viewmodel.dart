import 'package:flutter/foundation.dart';

import '/features/business/domain/entities/business_entity.dart';
import '/features/business/domain/usecases/get_my_businesses_usecase.dart';
import '/features/profile/domain/entities/profile_entity.dart';
import '/features/profile/domain/usecases/get_current_profile_usecase.dart';
import '/features/profile/domain/usecases/update_profile_role_usecase.dart';

class DashboardViewModel extends ChangeNotifier {
  final GetMyBusinessesUseCase getMyBusinessesUseCase;
  final GetCurrentProfileUseCase getCurrentProfileUseCase;
  final UpdateProfileRoleUseCase updateProfileRoleUseCase;

  DashboardViewModel({
    required this.getMyBusinessesUseCase,
    required this.getCurrentProfileUseCase,
    required this.updateProfileRoleUseCase,
  });

  List<BusinessEntity> _businesses = [];
  ProfileEntity? _profile;
  bool _isLoading = false;
  String? _error;

  List<BusinessEntity> get businesses => _businesses;
  ProfileEntity? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch profile and ensure role is microempresario
      _profile = await getCurrentProfileUseCase();
      if (_profile != null && _profile!.role != 'microempresario') {
        _profile = await updateProfileRoleUseCase('microempresario');
      }

      // Fetch businesses
      _businesses = await getMyBusinessesUseCase();
    } catch (e) {
      _error = 'Error al cargar el panel: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshBusinesses() async {
    try {
      _businesses = await getMyBusinessesUseCase();
      notifyListeners();
    } catch (e) {
      _error = 'Error al actualizar negocios: $e';
      notifyListeners();
    }
  }
}
