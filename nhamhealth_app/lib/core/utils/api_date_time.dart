/// Parses an API timestamp and returns it in the device's local timezone.
///
/// Offset-aware values (`Z`, `+07:00`, etc.) retain their exact instant.
/// Legacy Spring `LocalDateTime` values have no offset; those values are
/// interpreted as UTC, which is how timestamps are stored by the API server.
DateTime? parseApiDateTimeToLocal(Object? value) {
  final raw = '${value ?? ''}'.trim();
  if (raw.isEmpty) return null;

  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;
  if (_hasTimezoneOffset(raw)) return parsed.toLocal();

  return DateTime.utc(
    parsed.year,
    parsed.month,
    parsed.day,
    parsed.hour,
    parsed.minute,
    parsed.second,
    parsed.millisecond,
    parsed.microsecond,
  ).toLocal();
}

bool _hasTimezoneOffset(String value) => RegExp(
  r'(?:Z|[+-]\d{2}(?::?\d{2})?)$',
  caseSensitive: false,
).hasMatch(value);
