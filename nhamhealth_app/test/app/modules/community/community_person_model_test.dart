import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_person.dart';

void main() {
  test('community person reads relationship status from the API', () {
    final person = CommunityPerson.fromJson({
      'id': 7,
      'name': 'Sokha',
      'avatarUrl': '',
      'detail': 'Siem Reap',
      'mutualFriends': 1,
      'connectionStatus': 'friend',
    });

    expect(person.connectionStatus, 'FRIEND');
    expect(person.mutualFriends, 1);
  });
}
