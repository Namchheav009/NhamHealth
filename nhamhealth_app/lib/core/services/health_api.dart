import '../../models/api_health.dart';

abstract interface class HealthApi {
  String get baseUrl;

  Future<ApiHealth> getHealth();
}
