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


def load_tests(loader, tests, pattern):
    import unittest
    return unittest.TestSuite(unittest.FunctionTestCase(test) for test in (
        test_grams, test_garlic_cloves, test_fraction, test_two_quantities,
        test_eggs_keep_ingredient_name, test_em_dash_explanation_is_parsed,
    ))
