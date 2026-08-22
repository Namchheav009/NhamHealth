package com.nhamhealth.nhamhealth_api.service;

import java.text.Normalizer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.entity.FoodNutrition;
import com.nhamhealth.nhamhealth_api.repository.FoodNutritionRepository;

@Service
public class FoodDatabaseMatchingService {
    private static final int DEFAULT_CANDIDATE_LIMIT = 20;
    private static final Map<String, String> KNOWN_ALIASES = Map.ofEntries(
            Map.entry("white rice", "cooked rice"),
            Map.entry("steamed white rice", "cooked rice"),
            Map.entry("jasmine rice cooked", "cooked jasmine rice"),
            Map.entry("pork rice", "bai sach chrouk"),
            Map.entry("rice with pork", "bai sach chrouk"),
            Map.entry("khmer noodle", "num banh chok"),
            Map.entry("khmer noodles", "num banh chok"),
            Map.entry("rice noodle soup", "kuy teav"),
            Map.entry("beef lok lak", "lok lak"),
            Map.entry("rice porridge", "borbor"),
            Map.entry("fried noodle", "mee cha"),
            Map.entry("fried noodles", "mee cha"));

    private final FoodNutritionRepository repository;
    private final double reliableMatchThreshold;

    public FoodDatabaseMatchingService(
            FoodNutritionRepository repository,
            @Value("${app.ai.food.database-match-threshold:0.78}") double reliableMatchThreshold) {
        this.repository = repository;
        this.reliableMatchThreshold = reliableMatchThreshold;
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
                        .filter(candidate -> candidate.score() >= reliableMatchThreshold)
                        .findFirst())
                .toList();
    }

    private List<MatchCandidate> rankAgainstCatalog(
            String detectedName, List<FoodNutrition> catalog, int limit) {
        String normalizedDetected = normalize(detectedName);
        if (normalizedDetected.isBlank() || "unknown food".equals(normalizedDetected)) {
            return List.of();
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
                .filter(candidate -> candidate.score() >= reliableMatchThreshold)
                .findFirst();
    }

    public String normalize(String value) {
        if (value == null || value.isBlank()) return "";
        String normalized = Normalizer.normalize(value, Normalizer.Form.NFKD)
                .replaceAll("\\p{M}+", "")
                .toLowerCase(Locale.ROOT)
                .replaceAll("[^a-z0-9\\p{L}]+", " ")
                .trim()
                .replaceAll("\\s+", " ");
        String known = KNOWN_ALIASES.get(normalized);
        if (known != null) return known;
        List<String> tokens = Arrays.stream(normalized.split(" "))
                .filter(token -> !token.isBlank())
                .map(this::singularize)
                .toList();
        String result = String.join(" ", tokens);
        return KNOWN_ALIASES.getOrDefault(result, result);
    }

    private String singularize(String token) {
        if (!token.matches("[a-z]+") || token.length() <= 3) return token;
        if (token.endsWith("ies") && token.length() > 4) {
            return token.substring(0, token.length() - 3) + "y";
        }
        if (token.endsWith("ches") || token.endsWith("shes") || token.endsWith("xes")) {
            return token.substring(0, token.length() - 2);
        }
        if (token.endsWith("s") && !token.endsWith("ss")
                && !token.endsWith("us") && !token.endsWith("is")) {
            return token.substring(0, token.length() - 1);
        }
        return token;
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
