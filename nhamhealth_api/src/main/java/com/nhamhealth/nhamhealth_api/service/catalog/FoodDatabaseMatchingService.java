package com.nhamhealth.nhamhealth_api.service.catalog;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.entity.FoodNutrition;
import com.nhamhealth.nhamhealth_api.repository.catalog.FoodNutritionRepository;

@Service
public class FoodDatabaseMatchingService {
    private static final int DEFAULT_CANDIDATE_LIMIT = 20;

    private final FoodNutritionRepository repository;
    private final FoodCorrectionSuggestionService correctionSuggestionService;
    private final FoodNameNormalizer nameNormalizer;
    private final double reliableMatchThreshold;

    @Autowired
    public FoodDatabaseMatchingService(
            FoodNutritionRepository repository,
            FoodCorrectionSuggestionService correctionSuggestionService,
            FoodNameNormalizer nameNormalizer,
            @Value("${app.ai.food.database-match-threshold:0.78}") double reliableMatchThreshold) {
        this.repository = repository;
        this.correctionSuggestionService = correctionSuggestionService;
        this.nameNormalizer = nameNormalizer;
        this.reliableMatchThreshold = reliableMatchThreshold;
    }

    FoodDatabaseMatchingService(
            FoodNutritionRepository repository, double reliableMatchThreshold) {
        this(repository, null, new FoodNameNormalizer(), reliableMatchThreshold);
    }

    @Transactional(readOnly = true)
    public List<MatchCandidate> findCandidates(String detectedName) {
        return findCandidates(detectedName, DEFAULT_CANDIDATE_LIMIT);
    }

    @Transactional(readOnly = true)
    public List<MatchCandidate> findCandidates(String detectedName, int requestedLimit) {
        int limit = Math.clamp(requestedLimit, 1, DEFAULT_CANDIDATE_LIMIT);
        return rankAgainstCatalog(detectedName, repository.findAllByActiveTrue(), limit);
    }

    @Transactional(readOnly = true)
    public List<Optional<MatchCandidate>> findReliableMatches(List<String> detectedNames) {
        if (detectedNames == null || detectedNames.isEmpty()) return List.of();
        List<FoodNutrition> catalog = repository.findAllByActiveTrue();
        return detectedNames.stream()
                .map(name -> rankAgainstCatalog(name, catalog, DEFAULT_CANDIDATE_LIMIT).stream()
                        .filter(candidate -> isReliable(name, candidate))
                        .findFirst())
                .toList();
    }

    private List<MatchCandidate> rankAgainstCatalog(
            String detectedName, List<FoodNutrition> catalog, int limit) {
        String normalizedDetected = normalize(detectedName);
        if (normalizedDetected.isBlank() || "unknown food".equals(normalizedDetected)) {
            return List.of();
        }
        if (correctionSuggestionService != null) {
            normalizedDetected = correctionSuggestionService
                    .findLearnedCorrection(normalizedDetected)
                    .map(this::normalize)
                    .orElse(normalizedDetected);
        }
        List<MatchCandidate> candidates = new ArrayList<>();
        for (FoodNutrition food : catalog) {
            double bestScore = similarity(normalizedDetected, normalize(food.getName()));
            String aliases = food.getAliases();
            if (aliases != null && !aliases.isBlank()) {
                for (String alias : aliases.split("[,;|\\n]")) {
                    bestScore = Math.max(bestScore, similarity(normalizedDetected, normalize(alias)));
                }
            }
            if (bestScore > 0) candidates.add(new MatchCandidate(food, roundScore(bestScore)));
        }
        candidates.sort(Comparator
                .comparingDouble(MatchCandidate::score).reversed()
                .thenComparing(candidate -> candidate.food().getName(), String.CASE_INSENSITIVE_ORDER));
        return List.copyOf(candidates.subList(0, Math.min(limit, candidates.size())));
    }

    @Transactional(readOnly = true)
    public Optional<MatchCandidate> findReliableMatch(String detectedName) {
        return findCandidates(detectedName).stream()
                .filter(candidate -> isReliable(detectedName, candidate))
                .findFirst();
    }

    private boolean isReliable(String detectedName, MatchCandidate candidate) {
        if (candidate.score() >= reliableMatchThreshold) return true;
        String detected = normalize(detectedName);
        FoodNutrition food = candidate.food();
        if (hasStrongCoreTokenMatch(detected, normalize(food.getName()))) return true;
        String aliases = food.getAliases();
        if (aliases == null || aliases.isBlank()) return false;
        for (String alias : aliases.split("[,;|\\n]")) {
            if (hasStrongCoreTokenMatch(detected, normalize(alias))) return true;
        }
        return false;
    }

    /**
     * Accepts preparation variants such as "diced chicken breast" and
     * "grilled chicken breast", while refusing broad one-word matches such as
     * "rice" against every rice dish in the catalog.
     */
    private boolean hasStrongCoreTokenMatch(String left, String right) {
        if (left.isBlank() || right.isBlank()) return false;
        Set<String> leftTokens = meaningfulTokens(left);
        Set<String> rightTokens = meaningfulTokens(right);
        if (leftTokens.size() < 2 || rightTokens.size() < 2) return false;
        Set<String> shared = new HashSet<>(leftTokens);
        shared.retainAll(rightTokens);
        if (shared.size() < 2) return false;
        double coverage = (double) shared.size() / Math.min(leftTokens.size(), rightTokens.size());
        return coverage >= 0.66;
    }

    private Set<String> meaningfulTokens(String value) {
        Set<String> tokens = new HashSet<>();
        for (String token : value.split(" ")) {
            if (token.length() >= 3 && !PREPARATION_WORDS.contains(token)) tokens.add(token);
        }
        return tokens;
    }

    private static final Set<String> PREPARATION_WORDS = Set.of(
            "fresh", "cooked", "diced", "sliced", "chopped", "steamed",
            "grilled", "fried", "boiled", "roasted", "baked", "tender",
            "organic", "plain", "mixed", "light", "crispy");

    public String normalize(String value) {
        return nameNormalizer.normalize(value);
    }

    private double similarity(String left, String right) {
        if (left.equals(right)) return 1;
        if (left.isBlank() || right.isBlank()) return 0;
        Set<String> leftTokens = new HashSet<>(List.of(left.split(" ")));
        Set<String> rightTokens = new HashSet<>(List.of(right.split(" ")));
        Set<String> intersection = new HashSet<>(leftTokens);
        intersection.retainAll(rightTokens);
        Set<String> union = new HashSet<>(leftTokens);
        union.addAll(rightTokens);
        double tokenScore = union.isEmpty() ? 0 : (double) intersection.size() / union.size();
        double editScore = editSimilarity(left, right);
        double containsBonus = left.contains(right) || right.contains(left) ? 0.08 : 0;
        return Math.min(1, tokenScore * 0.72 + editScore * 0.28 + containsBonus);
    }

    private double editSimilarity(String left, String right) {
        int[] previous = new int[right.length() + 1];
        for (int column = 0; column <= right.length(); column++) previous[column] = column;
        for (int row = 1; row <= left.length(); row++) {
            int[] current = new int[right.length() + 1];
            current[0] = row;
            for (int column = 1; column <= right.length(); column++) {
                int cost = left.charAt(row - 1) == right.charAt(column - 1) ? 0 : 1;
                current[column] = Math.min(
                        Math.min(current[column - 1] + 1, previous[column] + 1),
                        previous[column - 1] + cost);
            }
            previous = current;
        }
        return 1 - (double) previous[right.length()] / Math.max(left.length(), right.length());
    }

    private double roundScore(double value) {
        return Math.round(value * 1_000) / 1_000.0;
    }

    public record MatchCandidate(FoodNutrition food, double score) {
    }
}
