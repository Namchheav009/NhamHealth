enum CommunitySection { feed, people }

enum CommunityFeedFilter { forYou, following, latest }

enum FriendsView { friends, followers, following, addFriends }

enum PeopleFilter { all, mutualFriends }

enum FriendshipStatus {
  none,
  outgoingPending,
  incomingPending,
  friends,
  blocked;

  factory FriendshipStatus.fromApi(String? value) => switch (value
      ?.trim()
      .toUpperCase()) {
    'OUTGOING_PENDING' => FriendshipStatus.outgoingPending,
    'INCOMING_PENDING' => FriendshipStatus.incomingPending,
    'FRIENDS' || 'FRIEND' => FriendshipStatus.friends,
    'BLOCKED' => FriendshipStatus.blocked,
    _ => FriendshipStatus.none,
  };

  String get apiValue => switch (this) {
    FriendshipStatus.none => 'NONE',
    FriendshipStatus.outgoingPending => 'OUTGOING_PENDING',
    FriendshipStatus.incomingPending => 'INCOMING_PENDING',
    FriendshipStatus.friends => 'FRIENDS',
    FriendshipStatus.blocked => 'BLOCKED',
  };

  bool get canRequest => this == FriendshipStatus.none;
}

enum CommunityConnectionStatus {
  none,
  followsYou,
  following,
  friend;

  factory CommunityConnectionStatus.fromApi(String? value) {
    return switch (value?.trim().toUpperCase()) {
      'FOLLOWS_YOU' || 'FOLLOW_BACK' => CommunityConnectionStatus.followsYou,
      'FOLLOWING' => CommunityConnectionStatus.following,
      'FRIEND' => CommunityConnectionStatus.friend,
      _ => CommunityConnectionStatus.none,
    };
  }

  String get apiValue => switch (this) {
    CommunityConnectionStatus.none => 'NONE',
    CommunityConnectionStatus.followsYou => 'FOLLOWS_YOU',
    CommunityConnectionStatus.following => 'FOLLOWING',
    CommunityConnectionStatus.friend => 'FRIEND',
  };

  bool get isFollowing =>
      this == CommunityConnectionStatus.following ||
      this == CommunityConnectionStatus.friend;

  bool get followsViewer =>
      this == CommunityConnectionStatus.followsYou ||
      this == CommunityConnectionStatus.friend;

  static CommunityConnectionStatus fromDirections({
    required bool isFollowing,
    required bool followsViewer,
  }) {
    if (isFollowing && followsViewer) return CommunityConnectionStatus.friend;
    if (isFollowing) return CommunityConnectionStatus.following;
    if (followsViewer) return CommunityConnectionStatus.followsYou;
    return CommunityConnectionStatus.none;
  }
}
