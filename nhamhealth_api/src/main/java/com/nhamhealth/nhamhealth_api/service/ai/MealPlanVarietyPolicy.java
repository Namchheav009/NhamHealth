package com.nhamhealth.nhamhealth_api.service.ai;

import java.text.Normalizer;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

import com.nhamhealth.nhamhealth_api.entity.PlannerMeal;
import com.nhamhealth.nhamhealth_api.service.ai.IbmMealPlannerRecommendationService.DaySlotSelection;

/** Hard validation for model-generated meal plans. */
final class MealPlanVarietyPolicy {
    private MealPlanVarietyPolicy() {
    }

    static boolean accepts(
            List<DaySlotSelection> selections,
            Map<LocalDate, List<String>> slotsPerDate,
            List<PlannerMeal> candidates,
            Set<Integer> recentlyUsedMealIds) {
        int requiredCount = slotsPerDate.values().stream().mapToInt(List::size).sum();
        if (selections == null || selections.size() != requiredCount) {
            return false;
        }

        Set<String> requiredKeys = new HashSet<>();
        slotsPerDate.forEach((date, slots) -> slots.forEach(slot ->
                requiredKeys.add(date + "|" + slot.toUpperCase(Locale.ROOT))));

        Set<Integer> candidateIds = new HashSet<>();
        Set<String> candidateNames = new HashSet<>();
        for (PlannerMeal meal : candidates) {
            if (meal == null || meal.getPlannerMealId() == null) {
                continue;
            }
            candidateIds.add(meal.getPlannerMealId());
            candidateNames.add(canonicalName(meal));
        }

        Set<String> selectedKeys = new HashSet<>();
        Set<Integer> selectedIds = new HashSet<>();
        Set<String> selectedNames = new HashSet<>();
        Map<Integer, Integer> frequency = new HashMap<>();
        Map<LocalDate, Set<Integer>> idsByDate = new HashMap<>();
        for (DaySlotSelection selection : selections) {
            if (selection == null || selection.selectedMeal() == null
                    || selection.selectedMeal().getPlannerMealId() == null) {
                return false;
            }
            String key = selection.date() + "|" + selection.slot().toUpperCase(Locale.ROOT);
            if (!requiredKeys.contains(key) || !selectedKeys.add(key)) {
                return false;
            }
            Integer mealId = selection.selectedMeal().getPlannerMealId();
            selectedIds.add(mealId);
            selectedNames.add(canonicalName(selection.selectedMeal()));
            frequency.merge(mealId, 1, Integer::sum);
            idsByDate.computeIfAbsent(selection.date(), ignored -> new HashSet<>()).add(mealId);
        }

        if (!selectedKeys.equals(requiredKeys)) {
            return false;
        }

        // A day must never show the same dish twice when enough distinct dishes exist.
        for (Map.Entry<LocalDate, List<String>> entry : slotsPerDate.entrySet()) {
            int slotCount = entry.getValue().size();
            if (candidateIds.size() >= slotCount
                    && idsByDate.getOrDefault(entry.getKey(), Set.of()).size() != slotCount) {
                return false;
            }
        }

        // If the catalogue can cover the request, both IDs and canonical dish names
        // must be unique across the complete plan.
        if (candidateIds.size() >= requiredCount && selectedIds.size() != requiredCount) {
            return false;
        }
        if (candidateNames.size() >= requiredCount && selectedNames.size() != requiredCount) {
            return false;
        }

        // Rebalancing should produce a genuinely fresh plan whenever enough unused
        // catalogue entries are available.
        Set<Integer> recent = recentlyUsedMealIds == null ? Set.of() : recentlyUsedMealIds;
        long freshCandidateCount = candidateIds.stream().filter(id -> !recent.contains(id)).count();
        if (freshCandidateCount >= requiredCount
                && selections.stream().anyMatch(selection -> recent.contains(
                        selection.selectedMeal().getPlannerMealId()))) {
            return false;
        }

        // When the catalogue is smaller than the plan, distribute unavoidable repeats
        // evenly instead of allowing one meal to dominate the week.
        if (!candidateIds.isEmpty() && candidateIds.size() < requiredCount) {
            int maximumFrequency = (int) Math.ceil((double) requiredCount / candidateIds.size());
            if (frequency.values().stream().anyMatch(count -> count > maximumFrequency)) {
                return false;
            }
        }
        return true;
    }

    private static String canonicalName(PlannerMeal meal) {
        String value = meal.getNameEn();
        if (value == null || value.isBlank()) {
            value = meal.getNameKm();
        }
        if (value == null || value.isBlank()) {
            return "meal-" + meal.getPlannerMealId();
        }
        return Normalizer.normalize(value, Normalizer.Form.NFKC)
                .toLowerCase(Locale.ROOT)
                .replaceAll("[^\\p{L}\\p{N}]+", " ")
                .trim();
    }
}
