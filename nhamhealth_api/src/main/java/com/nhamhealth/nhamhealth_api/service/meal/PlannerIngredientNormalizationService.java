package com.nhamhealth.nhamhealth_api.service.meal;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.entity.Ingredient;
import com.nhamhealth.nhamhealth_api.entity.PlannerMeal;
import com.nhamhealth.nhamhealth_api.repository.catalog.IngredientRepository;
import com.nhamhealth.nhamhealth_api.repository.meal.PlannerMealRepository;

@Service
public class PlannerIngredientNormalizationService {
    private static final Pattern AMOUNT = Pattern.compile(
            "^\\s*(\\d+(?:\\.\\d+)?)\\s*(kg|mg|g|ml|l|tsp|tbsp|cups?|pieces?|pcs?)?\\s+(.+?)\\s*$",
            Pattern.CASE_INSENSITIVE);
    private static final Map<String, String> UNITS = Map.ofEntries(
            Map.entry("piece", "piece"), Map.entry("pieces", "piece"), Map.entry("pc", "piece"),
            Map.entry("pcs", "piece"), Map.entry("cup", "cup"), Map.entry("cups", "cup"),
            Map.entry("kg", "kg"), Map.entry("mg", "mg"), Map.entry("g", "g"),
            Map.entry("ml", "ml"), Map.entry("l", "l"), Map.entry("tsp", "tsp"),
            Map.entry("tbsp", "tbsp"));

    private final PlannerMealRepository plannerMeals;
    private final IngredientRepository ingredients;
    private final JdbcTemplate jdbc;

    public PlannerIngredientNormalizationService(
            PlannerMealRepository plannerMeals, IngredientRepository ingredients, JdbcTemplate jdbc) {
        this.plannerMeals = plannerMeals;
        this.ingredients = ingredients;
        this.jdbc = jdbc;
    }

    @Transactional
    public NormalizationResult normalizeAll() {
        int mealsUpdated = 0;
        int ingredientRows = 0;
        int ingredientsCreated = 0;
        List<String> skipped = new ArrayList<>();
        for (PlannerMeal meal : plannerMeals.findAllByOrderByNameEnAsc()) {
            List<Draft> drafts = parse(meal.getIngredientsText(), meal.getIngredientsTextKm());
            if (drafts.isEmpty()) {
                skipped.add(meal.getNameEn());
                continue;
            }
            SyncResult result = sync(meal, drafts);
            mealsUpdated++;
            ingredientRows += result.rows();
            ingredientsCreated += result.created();
        }
        return new NormalizationResult(mealsUpdated, ingredientRows, ingredientsCreated, skipped);
    }

    @Transactional
    public SyncResult sync(PlannerMeal meal) {
        return sync(meal, parse(meal.getIngredientsText(), meal.getIngredientsTextKm()));
    }

    private SyncResult sync(PlannerMeal meal, List<Draft> parsed) {
        LinkedHashMap<String, Draft> unique = new LinkedHashMap<>();
        for (Draft draft : parsed) {
            unique.putIfAbsent(draft.name().toLowerCase(Locale.ROOT), draft);
        }
        List<Draft> drafts = new ArrayList<>(unique.values());
        jdbc.update("delete from public.planner_meal_ingredients where planner_meal_id = ?",
                meal.getPlannerMealId());
        int created = 0;
        for (int index = 0; index < drafts.size(); index++) {
            Draft draft = drafts.get(index);
            Ingredient ingredient = ingredients.findByIngredientNameIgnoreCase(draft.name()).orElse(null);
            if (ingredient == null) {
                ingredient = new Ingredient();
                ingredient.setIngredientName(draft.name());
                ingredient.setIngredientType("General");
                ingredient.setDefaultUnit(draft.unit());
                ingredient = ingredients.save(ingredient);
                created++;
            } else if ((ingredient.getDefaultUnit() == null || ingredient.getDefaultUnit().isBlank())
                    && draft.unit() != null) {
                ingredient.setDefaultUnit(draft.unit());
            }
            jdbc.update("""
                    insert into public.planner_meal_ingredients
                        (planner_meal_id, ingredient_id, quantity, unit, display_order)
                    values (?, ?, ?, ?, ?)
                    """, meal.getPlannerMealId(), ingredient.getIngredientId(), draft.quantity(), draft.unit(), index + 1);
            upsertTranslation(ingredient, "en", ingredient.getIngredientName());
            if (draft.nameKm() != null) upsertTranslation(ingredient, "km", draft.nameKm());
        }
        meal.setIngredientsText(toEnglishText(drafts));
        meal.setIngredientsTextKm(toKhmerText(drafts));
        plannerMeals.save(meal);
        return new SyncResult(drafts.size(), created);
    }

    private void upsertTranslation(Ingredient ingredient, String language, String name) {
        jdbc.update("""
                insert into public.ingredient_translations (ingredient_id, language_code, name)
                values (?, ?, ?)
                on conflict (ingredient_id, language_code) do update set name = excluded.name
                """, ingredient.getIngredientId(), language, name);
    }

    public List<Draft> parse(String english, String khmer) {
        List<String> enParts = split(english);
        List<String> kmParts = split(khmer);
        List<Draft> result = new ArrayList<>();
        for (int i = 0; i < enParts.size(); i++) {
            Draft draft = parsePart(enParts.get(i), i < kmParts.size() ? kmParts.get(i) : null);
            if (draft != null) result.add(draft);
        }
        return result;
    }

    private Draft parsePart(String raw, String rawKm) {
        String[] pipe = raw.split("\\|", -1);
        if (pipe.length > 1) {
            String name = clean(pipe[0]);
            if (name == null) return null;
            BigDecimal quantity = decimal(pipe.length > 1 ? pipe[1] : null);
            String unit = unit(pipe.length > 2 ? pipe[2] : null);
            String nameKm = clean(pipe.length > 3 ? pipe[3] : khmerName(rawKm));
            return new Draft(name, quantity, unit, nameKm);
        }
        Matcher matcher = AMOUNT.matcher(raw);
        if (matcher.matches()) {
            return new Draft(clean(matcher.group(3)), decimal(matcher.group(1)), unit(matcher.group(2)),
                    khmerName(rawKm));
        }
        String name = clean(raw);
        return name == null ? null : new Draft(name, null, null, khmerName(rawKm));
    }

    private List<String> split(String text) {
        if (text == null || text.isBlank()) return List.of();
        return Pattern.compile("[;\\r\\n]+").splitAsStream(text)
                .map(String::trim).filter(value -> !value.isBlank()).toList();
    }

    private String khmerName(String raw) {
        if (raw == null) return null;
        String first = raw.split("\\|", -1)[0].trim();
        Matcher matcher = AMOUNT.matcher(first);
        return clean(matcher.matches() ? matcher.group(3) : first);
    }

    private String toEnglishText(List<Draft> drafts) {
        return drafts.stream().map(draft -> String.join(" | ", draft.name(), value(draft.quantity()),
                value(draft.unit()), value(draft.nameKm()))).reduce((a, b) -> a + "\n" + b).orElse(null);
    }

    private String toKhmerText(List<Draft> drafts) {
        String value = drafts.stream().filter(draft -> draft.nameKm() != null)
                .map(draft -> String.join(" | ", draft.nameKm(), value(draft.quantity()), value(draft.unit())))
                .reduce((a, b) -> a + "\n" + b).orElse("");
        return value.isBlank() ? null : value;
    }

    private BigDecimal decimal(String value) {
        try { return clean(value) == null ? null : new BigDecimal(value.trim()); }
        catch (NumberFormatException ignored) { return null; }
    }

    private String unit(String value) {
        String cleaned = clean(value);
        return cleaned == null ? null : UNITS.getOrDefault(cleaned.toLowerCase(Locale.ROOT), cleaned);
    }

    private String clean(String value) { return value == null || value.isBlank() ? null : value.trim(); }
    private String value(Object value) { return value == null ? "" : value.toString(); }

    public record Draft(String name, BigDecimal quantity, String unit, String nameKm) {}
    public record SyncResult(int rows, int created) {}
    public record NormalizationResult(int mealsUpdated, int ingredientRows, int ingredientsCreated,
            List<String> skippedMeals) {}
}
