import '../entities/profile_entity.dart';

abstract class ProfileRepository {
  Future<ProfileEntity?> getCurrentProfile();
  Future<ProfileEntity?> updateProfileRole(String role);
  Future<ProfileEntity?> updateProfile(Map<String, dynamic> data);
}
