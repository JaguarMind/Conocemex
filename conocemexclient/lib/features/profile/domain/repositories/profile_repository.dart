import '../entities/profile_entity.dart';

abstract class ProfileRepository {
  Future<ProfileEntity?> getCurrentProfile();
  Future<ProfileEntity?> updateProfileRole(String role);
}
