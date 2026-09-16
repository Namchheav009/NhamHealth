import '../../models/community/follow_connection_result.dart';
import '../../providers/community/follow_connections_provider.dart';

class FollowConnectionsRepository {
  const FollowConnectionsRepository({
    required FollowConnectionsProvider provider,
  }) : _provider = provider;

  final FollowConnectionsProvider _provider;

  Future<FollowConnectionResult> create(int receiverId) async =>
      FollowConnectionResult.fromJson(await _provider.create(receiverId));

  Future<FollowConnectionResult> accept(int requestId) async =>
      FollowConnectionResult.fromJson(await _provider.accept(requestId));

  Future<FollowConnectionResult> decline(int requestId) async =>
      FollowConnectionResult.fromJson(await _provider.decline(requestId));
}
