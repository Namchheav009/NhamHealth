class ParsedMealTextItem {
  const ParsedMealTextItem({required this.searchName, this.amount, this.unit});

  final String searchName;
  final double? amount;
  final String? unit;
}

class MealTextParser {
  const MealTextParser();

  List<ParsedMealTextItem> parse(String input) {
    final normalized = input
        .replaceAll(
          RegExp(r'\b(?:i\s+)?(?:ate|had|drank)\b', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\s+and\s+', caseSensitive: false), ',');
    return normalized
        .split(RegExp(r'[,;\n]+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .map(_parsePart)
        .where((item) => item.searchName.isNotEmpty)
        .take(12)
        .toList(growable: false);
  }

  ParsedMealTextItem _parsePart(String part) {
    final match = RegExp(
      r'^(\d+(?:\.\d+)?)\s*(g|gram|grams|kg|ml|cup|cups|bowl|bowls|serving|servings|piece|pieces)?\s+(?:of\s+)?(.+)$',
      caseSensitive: false,
    ).firstMatch(part);
    if (match == null) return ParsedMealTextItem(searchName: part);
    var amount = double.tryParse(match.group(1)!);
    var unit = match.group(2)?.toLowerCase();
    if (unit == 'kg' && amount != null) {
      amount *= 1000;
      unit = 'g';
    }
    return ParsedMealTextItem(
      searchName: match.group(3)!.trim(),
      amount: amount,
      unit: unit,
    );
  }
}
