package com.nhamhealth.nhamhealth_api.service.meal;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestClient;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.nhamhealth.nhamhealth_api.entity.PlannerMeal;
import com.nhamhealth.nhamhealth_api.repository.meal.PlannerMealRepository;

/** Generates only missing planner-meal ingredient lists; existing lists are never overwritten. */
@Service
public class PlannerMealIngredientBackfillService {
    private static final TypeReference<List<IngredientDraft>> INGREDIENT_LIST = new TypeReference<>() {};

    private final PlannerMealRepository plannerMeals;
    private final ObjectMapper mapper = new ObjectMapper();
    private final RestClient gemini;
    private final RestClient nvidia;
    private final String geminiApiKey;
    private final String geminiModel;
    private final String nvidiaApiKey;
    private final String nvidiaModel;

    public PlannerMealIngredientBackfillService(
            PlannerMealRepository plannerMeals,
            @Value("${app.ai.gemini.base-url:https://generativelanguage.googleapis.com/v1beta}") String geminiBaseUrl,
            @Value("${app.ai.gemini.api-key:}") String geminiApiKey,
            @Value("${app.ai.gemini.nutrition-model:${app.ai.gemini.model:gemini-3.5-flash-lite}}") String geminiModel,
            @Value("${app.ai.nvidia.base-url:https://integrate.api.nvidia.com/v1}") String nvidiaBaseUrl,
            @Value("${app.ai.nvidia.api-key:}") String nvidiaApiKey,
            @Value("${app.ai.nvidia.nutrition-model:${app.ai.nvidia.model:nvidia/nemotron-3.5-lightning-30b-a3b}}") String nvidiaModel) {
        this.plannerMeals = plannerMeals;
        this.gemini = RestClient.builder().baseUrl(trimTrailingSlash(geminiBaseUrl)).build();
        this.nvidia = RestClient.builder().baseUrl(trimTrailingSlash(nvidiaBaseUrl)).build();
        this.geminiApiKey = geminiApiKey;
        this.geminiModel = geminiModel;
        this.nvidiaApiKey = nvidiaApiKey;
        this.nvidiaModel = nvidiaModel;
    }

    @Transactional
    public BackfillResult backfillMissingIngredients() {
        List<String> updated = new ArrayList<>();
        List<String> failed = new ArrayList<>();
        int skipped = 0;
        for (PlannerMeal meal : plannerMeals.findAllByOrderByNameEnAsc()) {
            if (meal.getIngredientsText() != null && !meal.getIngredientsText().isBlank()) {
                skipped++;
                continue;
            }
            try {
                List<IngredientDraft> ingredients = generate(meal);
                if (ingredients.isEmpty()) {
                    failed.add(meal.getNameEn());
                    continue;
                }
                meal.setIngredientsText(toEnglishLines(ingredients));
                meal.setIngredientsTextKm(toKhmerLines(ingredients));
                updated.add(meal.getNameEn());
            } catch (Exception exception) {
                failed.add(meal.getNameEn());
            }
        }
        return new BackfillResult(updated, skipped, failed);
    }

    private List<IngredientDraft> generate(PlannerMeal meal) throws Exception {
        String prompt = promptFor(meal);
        Exception geminiFailure = null;
        if (geminiApiKey != null && !geminiApiKey.isBlank()) {
            try {
                return parse(gemini.post()
                        .uri("/models/" + geminiModel + ":generateContent")
                        .header("x-goog-api-key", geminiApiKey)
                        .contentType(MediaType.APPLICATION_JSON)
                        .body(Map.of("contents", List.of(Map.of("role", "user", "parts", List.of(Map.of("text", prompt)))),
                                "generationConfig", Map.of("temperature", 0.15, "maxOutputTokens", 1000)))
                        .retrieve().body(String.class), true);
            } catch (Exception exception) {
                geminiFailure = exception;
            }
        }
        if (nvidiaApiKey != null && !nvidiaApiKey.isBlank()) {
            return parse(nvidia.post().uri("/chat/completions")
                    .header("Authorization", "Bearer " + nvidiaApiKey)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(Map.of("model", nvidiaModel, "temperature", 0.15, "max_tokens", 1000,
                            "messages", List.of(Map.of("role", "user", "content", prompt))))
                    .retrieve().body(String.class), false);
        }
        throw geminiFailure == null ? new IllegalStateException("No AI provider is configured.") : geminiFailure;
    }

    private List<IngredientDraft> parse(String response, boolean fromGemini) throws Exception {
        JsonNode root = mapper.readTree(response);
        String text = fromGemini
                ? root.path("candidates").path(0).path("content").path("parts").path(0).path("text").asText()
                : root.path("choices").path(0).path("message").path("content").asText();
        String json = text.replaceAll("(?s)^\\s*```(?:json)?\\s*|\\s*```\\s*$", "").trim();
        List<IngredientDraft> ingredients = mapper.readValue(json, INGREDIENT_LIST);
        return ingredients.stream()
                .filter(item -> item.name() != null && !item.name().isBlank())
                .limit(20)
                .toList();
    }

    private String promptFor(PlannerMeal meal) {
        return "Create a practical ingredient list for this healthy meal. Return ONLY a JSON array, no markdown. "
                + "Each object must be {\"name\":\"English ingredient\",\"quantity\":number,\"unit\":\"g/ml/piece/tbsp\",\"nameKm\":\"Khmer name\"}. "
                + "Use realistic one-serving amounts. Do not include vague items. Meal: " + meal.getNameEn()
                + ". Description: " + (meal.getDescriptionEn() == null ? "" : meal.getDescriptionEn());
    }

    private static String toEnglishLines(List<IngredientDraft> ingredients) {
        return ingredients.stream().map(item -> line(item.name(), item.quantity(), item.unit(), item.nameKm())).reduce((a, b) -> a + "\n" + b).orElse("");
    }

    private static String toKhmerLines(List<IngredientDraft> ingredients) {
        return ingredients.stream().map(item -> line(item.nameKm(), item.quantity(), item.unit(), "")).reduce((a, b) -> a + "\n" + b).orElse("");
    }

    private static String line(String name, Number quantity, String unit, String khmer) {
        return String.join(" | ", name == null ? "" : name.trim(), quantity == null ? "" : quantity.toString(),
                unit == null ? "" : unit.trim(), khmer == null ? "" : khmer.trim()).replaceFirst("( \\| )+$", "");
    }

    private static String trimTrailingSlash(String value) {
        return value == null ? "" : value.replaceFirst("/+$", "");
    }

    private record IngredientDraft(String name, Number quantity, String unit, String nameKm) {}
    public record BackfillResult(List<String> updated, int skipped, List<String> failed) {}
}
