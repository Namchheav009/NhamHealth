import '../../auth/models/authenticated_user_model.dart';
import 'home_dashboard_model.dart';

class HomeRouteArguments {
  const HomeRouteArguments({required this.user, this.initialDashboard});

  final AuthenticatedUser user;
  final HomeDashboardModel? initialDashboard;
}
