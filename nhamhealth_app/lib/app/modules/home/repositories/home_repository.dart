import '../models/home_dashboard_model.dart';
import '../providers/home_provider.dart';

class HomeRepository {
  final HomeProvider provider;

  HomeRepository({
    required this.provider,
  });

  Future<HomeDashboardModel> getHomeDashboard({DateTime? date}) {
    return provider.getHomeDashboard(date: date);
  }
}
