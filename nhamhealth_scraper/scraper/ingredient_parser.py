import re
from fractions import Fraction


UNICODE_FRACTIONS = {
    "½": "1/2",
    "⅓": "1/3",
    "⅔": "2/3",
    "¼": "1/4",
    "¾": "3/4",
    "⅛": "1/8",
    "⅜": "3/8",
    "⅝": "5/8",
    "⅞": "7/8",
}

UNIT_ALIASES = {
    "g": "g",
    "gram": "g",
    "grams": "g",
    "kg": "kg",
    "ml": "ml",
    "l": "l",
    "tbsp": "tbsp",
    "tablespoon": "tbsp",
    "tablespoons": "tbsp",
    "tsp": "tsp",
    "teaspoon": "tsp",
    "teaspoons": "tsp",
    "cup": "cup",
    "cups": "cup",
    "clove": "clove",
    "cloves": "clove",
    "piece": "piece",
    "pieces": "piece",
    "stalk": "stalk",
    "stalks": "stalk",
    "leaf": "leaf",
    "leaves": "leaf",
    "egg": "piece",
    "eggs": "piece",
}

UNIT_PATTERN = "|".join(
    sorted((re.escape(k) for k in UNIT_ALIASES), key=len, reverse=True)
)


def _replace_unicode_fractions(text: str) -> str:
    for symbol, ascii_fraction in UNICODE_FRACTIONS.items():
        text = text.replace(symbol, ascii_fraction)
    return text


def _parse_quantity(raw: str | None):
    if not raw:
        return None

    raw = raw.strip()

    try:
        if " " in raw and "/" in raw:
            whole, fraction = raw.split(" ", 1)
            return float(whole) + float(Fraction(fraction))
        if "/" in raw:
            return float(Fraction(raw))
        return float(raw)
    except Exception:
        return None


def _clean_note(text: str | None) -> str | None:
    if not text:
        return None
    cleaned = text.strip(" ,—-")
    return cleaned or None


def _split_multi_quantity_line(line: str) -> list[str]:
    # Example:
    # "1 carrot and 100 g daikon, julienned"
    # becomes two separately parseable ingredient strings.
    pieces = re.split(r"\s+and\s+(?=\d+(?:\.\d+)?(?:\s+\d+/\d+|/\d+)?\s)", line)
    return [p.strip() for p in pieces if p.strip()]


def parse_ingredient_line(original_text: str) -> list[dict]:
    """
    Parse one visible ingredient line.

    The original text is always preserved so admin review can fix ambiguous rows.
    Returns a list because some source lines contain two quantities.
    """
    text = " ".join(original_text.split())
    text = _replace_unicode_fractions(text)

    results = []

    for part in _split_multi_quantity_line(text):
        source_part = part

        # Separate a long explanatory note after an em dash.
        explanation = None
        if "—" in part:
            part, explanation = part.split("—", 1)
            part = part.strip()
            explanation = explanation.strip()

        # Pattern 1: 600 g pork shoulder, sliced
        m = re.match(
            rf"^(?P<qty>\d+(?:\.\d+)?(?:\s+\d+/\d+|/\d+)?)\s+"
            rf"(?P<unit>{UNIT_PATTERN})\b\s*"
            rf"(?P<rest>.+)$",
            part,
            flags=re.IGNORECASE,
        )

        if m:
            rest = m.group("rest").strip()
            name, comma, note = rest.partition(",")

            # "6 eggs, hard-boiled" uses the countable ingredient itself as
            # the matched unit.  Without this special case, the text after
            # "eggs" starts with a comma and produces an empty name.
            matched_unit = m.group("unit").lower()
            if matched_unit in {"egg", "eggs"} and not name.strip():
                name = matched_unit

            results.append(
                {
                    "ingredientName": name.strip(),
                    "quantity": _parse_quantity(m.group("qty")),
                    "unit": UNIT_ALIASES.get(matched_unit, matched_unit),
                    "preparationNote": _clean_note(note if comma else explanation),
                    "originalIngredientText": original_text.strip(),
                    "needsReview": False,
                }
            )
            continue

        # Pattern 2: 4 garlic cloves, pounded
        m = re.match(
            rf"^(?P<qty>\d+(?:\.\d+)?(?:\s+\d+/\d+|/\d+)?)\s+"
            rf"(?P<name>.+?)\s+"
            rf"(?P<unit>{UNIT_PATTERN})\b"
            rf"(?P<tail>.*)$",
            part,
            flags=re.IGNORECASE,
        )

        if m:
            tail = m.group("tail").strip()
            if tail.startswith(","):
                tail = tail[1:].strip()

            results.append(
                {
                    "ingredientName": m.group("name").strip(),
                    "quantity": _parse_quantity(m.group("qty")),
                    "unit": UNIT_ALIASES.get(m.group("unit").lower(), m.group("unit").lower()),
                    "preparationNote": _clean_note(tail or explanation),
                    "originalIngredientText": original_text.strip(),
                    "needsReview": False,
                }
            )
            continue

        # Pattern 3: 1 carrot
        m = re.match(
            r"^(?P<qty>\d+(?:\.\d+)?(?:\s+\d+/\d+|/\d+)?)\s+(?P<rest>.+)$",
            part,
        )

        if m:
            rest = m.group("rest").strip()
            name, comma, note = rest.partition(",")

            results.append(
                {
                    "ingredientName": name.strip(),
                    "quantity": _parse_quantity(m.group("qty")),
                    "unit": "piece",
                    "preparationNote": _clean_note(note if comma else explanation),
                    "originalIngredientText": original_text.strip(),
                    "needsReview": True,  # "1 carrot" is an inferred unit.
                }
            )
            continue

        # "To serve cucumber, tomato and a fried egg" and similar lines.
        lower = part.lower()
        if lower.startswith("to serve "):
            name = part[9:].strip()
            prep_note = "To serve"
        elif lower.startswith("to finish "):
            name = part[10:].strip()
            prep_note = "To finish"
        else:
            name = part
            prep_note = explanation

        results.append(
            {
                "ingredientName": name.strip(),
                "quantity": None,
                "unit": None,
                "preparationNote": _clean_note(prep_note),
                "originalIngredientText": original_text.strip(),
                "needsReview": True,
            }
        )

    return results
