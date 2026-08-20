package com.nhamhealth.nhamhealth_api.service;

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
import com.nhamhealth.nhamhealth_api.repository.MealFavoriteRepository;
import com.nhamhealth.nhamhealth_api.repository.MoodRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;
import com.nhamhealth.nhamhealth_api.repository.DailyWellnessSummaryRepository;
import com.nhamhealth.nhamhealth_api.repository.DailyNutrientTotalRepository;
import com.nhamhealth.nhamhealth_api.repository.WellnessProfileRepository;

@Service
public class AiMealRecommendationService {
    private final AiRecommendationRepository recommendationRepository;
    private final AiRecommendationItemRepository itemRepository;
    private final MealRepository mealRepository;
    private final MoodRepository moodRepository;
    private final UserRepository userRepository;
    private final MealFavoriteRepository favoriteRepository;
    private final DailyWellnessSummaryRepository dailySummaryRepository;
    private final DailyNutrientTotalRepository dailyNutrientRepository;
    private final WellnessProfileRepository wellnessProfileRepository;
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
            MealFavoriteRepository favoriteRepository,
            DailyWellnessSummaryRepository dailySummaryRepository,
            DailyNutrientTotalRepository dailyNutrientRepository,
            WellnessProfileRepository wellnessProfileRepository,
            @Value("${app.ai.nvidia.base-url:https://integrate.api.nvidia.com/v1}") String baseUrl,
            @Value("${app.ai.nvidia.api-key:}") String apiKey,
            @Value("${app.ai.nvidia.recommendation-model:nvidia/nemotron-3-nano-30b-a3b}") String model) {
        this.recommendationRepository = recommendationRepository;
        this.itemRepository = itemRepository;
        this.mealRepository = mealRepository;
        this.moodRepository = moodRepository;
        this.userRepository = userRepository;
        this.favoriteRepository = favoriteRepository;
        this.dailySummaryRepository = dailySummaryRepository;
        this.dailyNutrientRepository = dailyNutrientRepository;
        this.wellnessProfileRepository = wellnessProfileRepository;
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

        RecommendationContext context = recommendationContext(userId);
        ModelDecision decision = askModel(mood, catalog, context);
        if (decision == null || decision.mealIds().isEmpty()) {
            decision = fallbackDecision(mood, catalog, context);
        }

        Map<Integer, Meal> mealsById = new HashMap<>();
        catalog.forEach(meal -> mealsById.put(meal.getMealId(), meal));
        LinkedHashMap<Integer, String> selected = new LinkedHashMap<>();
        for (MealChoice choice : decision.mealIds()) {
            if (mealsById.containsKey(choice.id())) selected.putIfAbsent(choice.id(), choice.reason());
            if (selected.size() == 5) break;
        }
        if (selected.isEmpty()) decision = fallbackDecision(mood, catalog, context);
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

    private ModelDecision askModel(Mood mood, List<Meal> meals, RecommendationContext context) {
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
                    You are a wellness meal-ranking model. Select 3 to 5 meals only from the supplied
                    catalog. Rank for the user's mood, remaining nutrition today, activity level,
                    cooking effort, and prior favorites. Prefer a useful mix of categories instead of
                    near-duplicate meals. Favorites are preference signals, not mandatory selections.
                    Do not infer allergies or medical needs. Never invent IDs or nutrition values.
                    Each reason must name a concrete benefit from the supplied data in 18 words or less.
                    Return JSON only in this exact shape:
                    {"summary":"short explanation","meals":[{"id":1,"reason":"short reason"}]}
                    Mood: %s
                    User context: %s
                    Catalog: %s
                    """.formatted(mood.getMoodName(), mapper.writeValueAsString(context), catalog);
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

    private ModelDecision fallbackDecision(
            Mood mood, List<Meal> meals, RecommendationContext context) {
        String moodName = mood.getMoodName().toLowerCase();
        boolean lowEnergy = List.of("tired", "sleepy", "busy", "stressed", "drained").stream()
                .anyMatch(moodName::contains);
        List<Meal> ranked = meals.stream()
                .sorted(Comparator.comparingDouble(
                        (Meal meal) -> fallbackScore(meal, context, lowEnergy)).reversed())
                .toList();
        List<Meal> diverse = new ArrayList<>();
        var usedCategories = new java.util.HashSet<Integer>();
        for (Meal meal : ranked) {
            Integer categoryId = meal.getCategory().getCategoryId();
            if (usedCategories.add(categoryId)) diverse.add(meal);
            if (diverse.size() == 5) break;
        }
        for (Meal meal : ranked) {
            if (diverse.size() == 5) break;
            if (!diverse.contains(meal)) diverse.add(meal);
        }
        List<MealChoice> choices = diverse.stream().map(meal -> new MealChoice(
                meal.getMealId(), fallbackReason(meal, mood, context, lowEnergy))).toList();
        return new ModelDecision("Personalized meal choices based on your " + mood.getMoodName() + " mood.", choices);
    }

    private RecommendationContext recommendationContext(Integer userId) {
        var favoriteIds = favoriteRepository.findAllByUserUserIdOrderBySavedAtDesc(userId)
                .stream().map(value -> value.getMeal().getMealId()).distinct().limit(20).toList();
        String activityLevel = wellnessProfileRepository.findByUser_UserId(userId)
                .map(value -> value.getActivityLevel() == null ? "unknown" : value.getActivityLevel())
                .orElse("unknown");
        double remainingCalories = 0;
        double remainingProtein = 0;
        var summary = dailySummaryRepository.findByUser_UserIdAndSummaryDate(userId, LocalDate.now());
        if (summary.isPresent()) {
            for (var total : dailyNutrientRepository
                    .findByDailyWellnessSummaryDailySummaryId(summary.get().getDailySummaryId())) {
                double remaining = Math.max(0,
                        total.getGoalAmount().doubleValue() - total.getConsumedAmount().doubleValue());
                String nutrient = total.getNutrient().getNutrientName().toLowerCase();
                if (nutrient.contains("calorie")) remainingCalories = remaining;
                if (nutrient.contains("protein")) remainingProtein = remaining;
            }
        }
        return new RecommendationContext(activityLevel, remainingCalories, remainingProtein, favoriteIds);
    }

    private double fallbackScore(Meal meal, RecommendationContext context, boolean lowEnergy) {
        double protein = meal.getProteinGramsCached() == null ? 0 : meal.getProteinGramsCached().doubleValue();
        double calories = meal.getCaloriesCached() == null ? 0 : meal.getCaloriesCached().doubleValue();
        double score = protein * (context.remainingProteinGrams() > 0 ? 2.5 : 1.4);
        if (lowEnergy) score += calories * 0.025;
        if (context.remainingCalories() > 0 && calories > 0) {
            double usefulPortion = Math.min(700, Math.max(250, context.remainingCalories() * 0.45));
            score -= Math.abs(calories - usefulPortion) * 0.018;
        }
        if (context.favoriteMealIds().contains(meal.getMealId())) score += 10;
        if (meal.getCookingTimeMinutes() != null && meal.getCookingTimeMinutes() <= 30) score += 4;
        return score;
    }

    private String fallbackReason(
            Meal meal, Mood mood, RecommendationContext context, boolean lowEnergy) {
        if (context.favoriteMealIds().contains(meal.getMealId())) {
            return "Matches your saved preferences and suits your " + mood.getMoodName() + " mood.";
        }
        if (context.remainingProteinGrams() > 0 && meal.getProteinGramsCached() != null) {
            return "Adds " + meal.getProteinGramsCached().stripTrailingZeros().toPlainString()
                    + " g protein toward today's remaining goal.";
        }
        if (lowEnergy) return "Provides practical energy for a " + mood.getMoodName() + " day.";
        return "A balanced, varied option for your " + mood.getMoodName() + " mood.";
    }

    private String limit(String value, int maxLength) {
        if (value == null || value.isBlank()) return "Selected for your mood.";
        return value.length() <= maxLength ? value : value.substring(0, maxLength);
    }

    private record MealChoice(Integer id, String reason) {}
    private record ModelDecision(String summary, List<MealChoice> mealIds) {}
    private record RecommendationContext(
            String activityLevel,
            double remainingCalories,
            double remainingProteinGrams,
            List<Integer> favoriteMealIds) {}
}
