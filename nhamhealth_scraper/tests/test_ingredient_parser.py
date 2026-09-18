from scraper.ingredient_parser import parse_ingredient_line


def test_grams():
    result = parse_ingredient_line("600 g pork shoulder, sliced 5 mm thick")[0]
    assert result["ingredientName"] == "pork shoulder"
    assert result["quantity"] == 600
    assert result["unit"] == "g"


def test_garlic_cloves():
    result = parse_ingredient_line("4 garlic cloves, pounded")[0]
    assert result["ingredientName"] == "garlic"
    assert result["quantity"] == 4
    assert result["unit"] == "clove"


def test_fraction():
    result = parse_ingredient_line("½ cup cooked rice")[0]
    assert result["quantity"] == 0.5
    assert result["unit"] == "cup"


def test_two_quantities():
    result = parse_ingredient_line("1 carrot and 100 g daikon, julienned")
    assert len(result) == 2


def test_eggs_keep_ingredient_name():
    result = parse_ingredient_line("6 eggs, hard-boiled and peeled")[0]
    assert result["ingredientName"] == "eggs"
    assert result["quantity"] == 6
    assert result["unit"] == "piece"
    assert result["preparationNote"] == "hard-boiled and peeled"


def test_em_dash_explanation_is_parsed():
    result = parse_ingredient_line("2 tbsp fish sauce — plus more to serve")[0]
    assert result["ingredientName"] == "fish sauce"
    assert result["quantity"] == 2
    assert result["unit"] == "tbsp"
    assert result["preparationNote"] == "plus more to serve"


def test_culinary_units_and_ambiguous_flags():
    galangal = parse_ingredient_line("2 thumbs fresh galangal")[0]
    assert galangal["ingredientName"] == "fresh galangal"
    assert galangal["quantity"] == 2.0
    assert galangal["unit"] == "thumb"
    assert galangal["needsReview"] is True

    herbs = parse_ingredient_line("1 handful wild herbs and holy basil")[0]
    assert herbs["ingredientName"] == "wild herbs and holy basil"
    assert herbs["quantity"] == 1.0
    assert herbs["unit"] == "handful"
    assert herbs["needsReview"] is True

    bamboo = parse_ingredient_line("2 sections green bamboo tube")[0]
    assert bamboo["ingredientName"] == "green bamboo tube"
    assert bamboo["quantity"] == 2.0
    assert bamboo["unit"] == "section"
    assert bamboo["needsReview"] is True

    pinch_salt = parse_ingredient_line("1 pinch salt")[0]
    assert pinch_salt["ingredientName"] == "salt"
    assert pinch_salt["quantity"] == 1.0
    assert pinch_salt["unit"] == "pinch"
    assert pinch_salt["needsReview"] is True

    ginger = parse_ingredient_line("3 slices fresh ginger")[0]
    assert ginger["ingredientName"] == "fresh ginger"
    assert ginger["quantity"] == 3.0
    assert ginger["unit"] == "slice"
    assert ginger["needsReview"] is True


def test_clear_measurements_not_flagged():
    pork = parse_ingredient_line("600 g pork shoulder, sliced")[0]
    assert pork["needsReview"] is False

    garlic = parse_ingredient_line("4 cloves garlic, minced")[0]
    assert garlic["needsReview"] is False

    rice = parse_ingredient_line("250 ml thick coconut milk")[0]
    assert rice["needsReview"] is False


def load_tests(loader, tests, pattern):
    import unittest
    return unittest.TestSuite(unittest.FunctionTestCase(test) for test in (
        test_grams, test_garlic_cloves, test_fraction, test_two_quantities,
        test_eggs_keep_ingredient_name, test_em_dash_explanation_is_parsed,
        test_culinary_units_and_ambiguous_flags, test_clear_measurements_not_flagged,
    ))
