import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/core/utils/api_date_time.dart';

void main() {
  test('keeps the instant from an offset-aware API timestamp', () {
    final result = parseApiDateTimeToLocal('2026-09-25T10:30:00+07:00');

    expect(result, isNotNull);
    expect(result!.toUtc(), DateTime.utc(2026, 9, 25, 3, 30));
  });

  test('treats a legacy offset-less API timestamp as UTC', () {
    final result = parseApiDateTimeToLocal('2026-09-25T03:30:00');

    expect(result, isNotNull);
    expect(result!.toUtc(), DateTime.utc(2026, 9, 25, 3, 30));
  });

  test('returns null for an invalid or empty timestamp', () {
    expect(parseApiDateTimeToLocal(''), isNull);
    expect(parseApiDateTimeToLocal('not-a-date'), isNull);
  });
}
