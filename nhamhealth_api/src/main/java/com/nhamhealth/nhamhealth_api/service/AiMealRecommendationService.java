package com.nhamhealth.nhamhealth_api.service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestClient;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.nhamhealth.nhamhealth_api.entity.AiRecommendation;
import com.nhamhealth.nhamhealth_api.entity.AiRecommendationItem;
import com.nhamhealth.nhamhealth_api.entity.Meal;
import com.nhamhealth.nhamhealth_api.entity.Mood;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.AiRecommendationItemRepository;
import com.nhamhealth.nhamhealth_api.repository.AiRecommendationRepository;
import com.nhamhealth.nhamhealth_api.repository.MealRepository;
import com.nhamhealth.nhamhealth_api.repository.MoodRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

@Service
public class AiMealRecommendationService {
    private final AiRecommendationRepository recommendationRepository;
    private final AiRecommendationItemRepository itemRepository;
    private final MealRepository mealRepository;
    private final MoodRepository moodRepository;
    private final UserRepository userRepository;
    private final RestClient client;
    private final ObjectMapper mapper;
    private final String apiKey;
    private final String model;

    public AiMealRecommendationService(
            AiRecommendationRepository recommendationRepository,
            AiRecommendationItemRepository itemRepository,
            MealRepository mealRepository,
            MoodRepository moodRepository,
            UserRepository userRepository,
            @Value("${app.ai.nvidia.base-url:https://integrate.api.nvidia.com/v1}") String baseUrl,
            @Value("${app.ai.nvidia.api-key:}") String apiKey,
            @Value("${app.ai.nvidia.recommendation-model:nvidia/nemotron-3-nano-30b-a3b}") String model) {
        this.recommendationRepository = recommendationRepository;
        this.itemRepository = itemRepository;
        this.mealRepository = mealRepository;
        this.moodRepository = moodRepository;
        this.userRepository = userRepository;
        this.client = RestClient.builder().baseUrl(baseUrl).build();
        this.mapper = new ObjectMapper();
        this.apiKey = apiKey;
        this.model = model;
    }

    @Transactional
    public AiRecommendation generate(Integer userId, Integer moodId, boolean refresh) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found."));
        Mood mood = moodRepository.findById(moodId)
                .filter(value -> Boolean.TRUE.equals(value.getIsActive()))
                .orElseThrow(() -> new IllegalArgumentException("Select a valid active mood."));

        if (!refresh) {
            var existing = recommendationRepository
                    .findFirstByUserUserIdAndMoodMoodIdAndStatusAndCreatedAtGreaterThanEqualOrderByCreatedAtDesc(
                            userId, moodId, "ready", LocalDate.now().atStartOfDay());
            if (existing.isPresent()) return existing.get();
        }

        List<Meal> catalog = mealRepository.findAllByIsPublishedTrueOrderByMealNameAsc();
        if (catalog.isEmpty()) throw new IllegalStateException("No published meals are available.");

        ModelDecision decision = askModel(mood, catalog);
        if (decision == null || decision.mealIds().isEmpty()) decision = fallbackDecision(mood, catalog);

        Map<Integer, Meal> mealsById = new HashMap<>();
        catalog.forEach(meal -> mealsById.put(meal.getMealId(), meal));
        LinkedHashMap<Integer, String> selected = new LinkedHashMap<>();
        for (MealChoice choice : decision.mealIds()) {
            if (mealsById.containsKey(choice.id())) selected.putIfAbsent(choice.id(), choice.reason());
            if (selected.size() == 5) break;
        }
        if (selected.isEmpty()) decision = fallbackDecision(mood, catalog);
        if (selected.isEmpty()) {
            for (MealChoice choice : decision.mealIds()) selected.put(choice.id(), choice.reason());
        }

        LocalDateTime now = LocalDateTime.now();
        AiRecommendation recommendation = new AiRecommendation();
        recommendation.setUser(user);
        recommendation.setMood(mood);
        recommendation.setRequestText("Automatically recommend meals for mood: " + mood.getMoodName());
        recommendation.setResponseText(decision.summary());
        recommendation.setStatus("ready");
        recommendation.setCreatedAt(now);
        recommendation.setUpdatedAt(now);
        recommendationRepository.saveAndFlush(recommendation);

        int rank = 1;
        for (Map.Entry<Integer, String> choice : selected.entrySet()) {
            AiRecommendationItem item = new AiRecommendationItem();
            item.setRecommendation(recommendation);
            item.setMeal(mealsById.get(choice.getKey()));
            item.setRankOrder(rank++);
            item.setReasonText(limit(choice.getValue(), 500));
            item.setCreatedAt(now);
            itemRepository.save(item);
        }
        itemRepository.flush();
        return recommendation;
    }

    private ModelDecision askModel(Mood mood, List<Meal> meals) {
        if (apiKey == null || apiKey.isBlank()) return null;
        try {
            String catalog = mapper.writeValueAsString(meals.stream().map(meal -> Map.of(
                    "id", meal.getMealId(),
                    "name", meal.getMealName(),
                    "description", meal.getDescription() == null ? "" : meal.getDescription(),
                    "category", meal.getCategory().getCategoryName(),
                    "calories", meal.getCaloriesCached() == null ? 0 : meal.getCaloriesCached(),
                    "proteinGrams", meal.getProteinGramsCached() == null ? 0 : meal.getProteinGramsCached(),
                    "cookingMinutes", meal.getCookingTimeMinutes() == null ? 0 : meal.getCookingTimeMinutes()
            )).toList());
            String prompt = """
                    You are a meal recommendation model. Select 1 to 5 meals from the supplied catalog
                    that are suitable for the user's current mood. Consider energy, comfort, balance,
                    calories, protein, cooking effort, and the meal description. Never invent IDs.
                    Return JSON only in this exact shape:
                    {"summary":"short explanation","meals":[{"id":1,"reason":"short reason"}]}
                    Mood: %s
                    Catalog: %s
                    """.formatted(mood.getMoodName(), catalog);
            Map<String, Object> body = Map.of(
                    "model", model,
                    "temperature", 0.2,
                    "max_tokens", 900,
                    "chat_template_kwargs", Map.of("enable_thinking", false),
                    "messages", List.of(Map.of("role", "user", "content", prompt)));
            String responseBody = client.post().uri("/chat/completions")
                    .header("Authorization", "Bearer " + apiKey)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(body).retrieve().body(String.class);
            JsonNode response = mapper.readTree(responseBody);
            String content = response.path("choices").path(0).path("message").path("content").asText();
            String json = content.replaceFirst("(?s)^\\s*```(?:json)?\\s*", "")
                    .replaceFirst("(?s)\\s*```\\s*$", "").trim();
            JsonNode result = mapper.readTree(json);
            List<MealChoice> choices = new ArrayList<>();
            result.path("meals").forEach(node -> choices.add(new MealChoice(
                    node.path("id").asInt(), node.path("reason").asText("Selected by AI"))));
            return new ModelDecision(result.path("summary").asText("Meals selected for your mood."), choices);
        } catch (Exception ignored) {
            return null;
        }
    }

    private ModelDecision fallbackDecision(Mood mood, List<Meal> meals) {
        String moodName = mood.getMoodName().toLowerCase();
        boolean lowEnergy = List.of("tired", "sleepy", "busy", "stressed", "drained").stream()
                .anyMatch(moodName::contains);
        Comparator<Meal> comparator = Comparator.comparing(
                meal -> meal.getProteinGramsCached() == null ? BigDecimal.ZERO : meal.getProteinGramsCached());
        if (lowEnergy) comparator = comparator.thenComparing(
                meal -> meal.getCaloriesCached() == null ? BigDecimal.ZERO : meal.getCaloriesCached());
        List<MealChoice> choices = meals.stream().sorted(comparator.reversed()).limit(5)
                .map(meal -> new MealChoice(meal.getMealId(), lowEnergy
                        ? "Provides energy and protein for a " + mood.getMoodName() + " day."
                        : "A balanced option selected for your " + mood.getMoodName() + " mood."))
                .toList();
        return new ModelDecision("Personalized meal choices based on your " + mood.getMoodName() + " mood.", choices);
    }

    private String limit(String value, int maxLength) {
        if (value == null || value.isBlank()) return "Selected for your mood.";
        return value.length() <= maxLength ? value : value.substring(0, maxLength);
    }

    private record MealChoice(Integer id, String reason) {}
    private record ModelDecision(String summary, List<MealChoice> mealIds) {}
}
