package com.nhamhealth.nhamhealth_api.controller.api;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.nhamhealth.nhamhealth_api.dto.response.RecommendedMealResponse;
import com.nhamhealth.nhamhealth_api.entity.AiRecommendation;
import com.nhamhealth.nhamhealth_api.entity.AiRecommendationItem;
import com.nhamhealth.nhamhealth_api.entity.Meal;
import com.nhamhealth.nhamhealth_api.repository.ai.AiRecommendationItemRepository;
import com.nhamhealth.nhamhealth_api.repository.ai.AiRecommendationRepository;
import com.nhamhealth.nhamhealth_api.service.ai.AiMealRecommendationService;
import org.springframework.web.server.ResponseStatusException;

import static org.springframework.http.HttpStatus.UNAUTHORIZED;

@RestController
@RequestMapping("/api/v1/ai-recommendations")
public class AiRecommendationApiController {

    private final AiRecommendationRepository recommendationRepository;
    private final AiRecommendationItemRepository itemRepository;
    private final AiMealRecommendationService recommendationService;

    public AiRecommendationApiController(AiRecommendationRepository recommendationRepository,
            AiRecommendationItemRepository itemRepository,
            AiMealRecommendationService recommendationService) {
        this.recommendationRepository = recommendationRepository;
        this.itemRepository = itemRepository;
        this.recommendationService = recommendationService;
    }

    @GetMapping("/meals")
    public ResponseEntity<List<RecommendedMealResponse>> recommendedMeals(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam(required = false) Integer moodId) {
        Integer userId = authenticatedUserId(jwt);
        Optional<AiRecommendation> recommendation = moodId == null
                ? recommendationRepository.findFirstByUserUserIdAndStatusOrderByCreatedAtDesc(
                        userId, "ready")
                : recommendationRepository.findFirstByUserUserIdAndMoodMoodIdAndStatusOrderByCreatedAtDesc(
                        userId, moodId, "ready");

        if (recommendation.isEmpty()) return ResponseEntity.ok(List.of());

        return ResponseEntity.ok(toMealResponses(recommendation.get()));
    }

    @PostMapping("/meals/generate")
    public ResponseEntity<List<RecommendedMealResponse>> generateRecommendedMeals(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam(required = false) Integer moodId,
            @RequestParam(defaultValue = "false") boolean refresh) {
        return recommendationService.generate(authenticatedUserId(jwt), moodId, refresh)
                .map(recommendation -> ResponseEntity.ok(toMealResponses(recommendation)))
                .orElseGet(() -> ResponseEntity.ok(List.of()));
    }

    private Integer authenticatedUserId(Jwt jwt) {
        if (jwt == null) throw new ResponseStatusException(UNAUTHORIZED, "Authentication is required.");
        Number userId = jwt.getClaim("userId");
        if (userId == null) throw new ResponseStatusException(UNAUTHORIZED, "The access token has no user ID.");
        return userId.intValue();
    }

    private List<RecommendedMealResponse> toMealResponses(AiRecommendation recommendation) {
        return itemRepository
                .findAllByRecommendationRecommendationIdOrderByRankOrderAsc(recommendation.getRecommendationId())
                .stream()
                .filter(item -> Boolean.TRUE.equals(item.getMeal().getIsPublished()))
                .map(item -> toResponse(recommendation, item))
                .toList();
    }

    private RecommendedMealResponse toResponse(AiRecommendation recommendation, AiRecommendationItem item) {
        Meal meal = item.getMeal();
        double rating = 0;
        return new RecommendedMealResponse(
                meal.getMealId(), meal.getMealName(), meal.getMainImageUrl(),
                meal.getCaloriesCached() == null ? BigDecimal.ZERO : meal.getCaloriesCached(),
                meal.getProteinGramsCached(),
                meal.getCookingTimeMinutes(), rating, recommendation.getRecommendationId(),
                recommendation.getMood() == null ? null : recommendation.getMood().getMoodId(),
                item.getReasonText());
    }
}
