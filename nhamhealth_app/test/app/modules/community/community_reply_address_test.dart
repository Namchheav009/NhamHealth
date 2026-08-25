import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_comment.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_reply_address.dart';

void main() {
  const maya = CommunityComment(
    id: '1',
    author: 'Maya Chen',
    text: 'Original comment',
    createdAt: '2026-08-25T10:00:00Z',
  );
  const dara = CommunityComment(
    id: '2',
    author: 'Dara Sok',
    text: 'Another comment',
    createdAt: '2026-08-25T10:01:00Z',
  );

  test('places the addressed user first in a reply', () {
    final address = CommunityReplyAddress.fromComment(maya);

    expect(address.applyTo('Thank you'), '@Maya Chen Thank you');
  });

  test('switching reply targets replaces the generated addressee', () {
    final mayaAddress = CommunityReplyAddress.fromComment(maya);
    final daraAddress = CommunityReplyAddress.fromComment(dara);

    expect(
      daraAddress.applyTo('@Maya Chen Thank you', replacing: mayaAddress),
      '@Dara Sok Thank you',
    );
  });

  test('cancelling removes only the generated reply prefix', () {
    final address = CommunityReplyAddress.fromComment(maya);

    expect(address.removeFrom('@Maya Chen Thanks!'), 'Thanks!');
    expect(
      address.removeFrom('Custom @Maya Chen text'),
      'Custom @Maya Chen text',
    );
  });
}
