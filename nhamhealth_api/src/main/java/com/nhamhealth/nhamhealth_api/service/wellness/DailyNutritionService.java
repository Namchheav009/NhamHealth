package com.nhamhealth.nhamhealth_api.service.wellness;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Locale;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.dto.request.DailyNutritionUpdateRequest;
import com.nhamhealth.nhamhealth_api.entity.DailyNutrientTotal;
import com.nhamhealth.nhamhealth_api.entity.DailyNutritionSourceLog;
import com.nhamhealth.nhamhealth_api.entity.DailyWellnessSummary;
import com.nhamhealth.nhamhealth_api.entity.Nutrient;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.catalog.NutrientRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.repository.wellness.DailyNutrientTotalRepository;
import com.nhamhealth.nhamhealth_api.repository.wellness.DailyNutritionSourceLogRepository;
import com.nhamhealth.nhamhealth_api.repository.wellness.DailyWellnessSummaryRepository;

@Service
public class DailyNutritionService {
    private final UserRepository userRepository;
    private final DailyWellnessSummaryRepository summaryRepository;
    private final DailyNutrientTotalRepository totalRepository;
    private final NutrientRepository nutrientRepository;
    private final DailyNutritionSourceLogRepository sourceLogRepository;

    public DailyNutritionService(UserRepository userRepository,
            DailyWellnessSummaryRepository summaryRepository,
            DailyNutrientTotalRepository totalRepository,
            NutrientRepository nutrientRepository,
            DailyNutritionSourceLogRepository sourceLogRepository) {
        this.userRepository = userRepository;
        this.summaryRepository = summaryRepository;
        this.totalRepository = totalRepository;
        this.nutrientRepository = nutrientRepository;
        this.sourceLogRepository = sourceLogRepository;
    }

    @Transactional
    public void add(Integer userId, DailyNutritionUpdateRequest request) {
        LocalDate date = request.date() == null ? LocalDate.now() : request.date();
        if (hasText(request.sourceType()) != hasText(request.sourceId())) {
            throw new IllegalArgumentException("Nutrition source type and ID must be provided together");
        }
        if (hasSource(request.sourceType(), request.sourceId())) {
            upsertSource(userId, date, request.sourceType(), request.sourceId(),
                    value(request.calories()), value(request.protein()), value(request.carbs()),
                    value(request.fat()), value(request.water()), value(request.fiber()), value(request.sugar()));
            updateInsight(userId, date, request.aiRecommendation());
            return;
        }
        DailyWellnessSummary summary = summaryRepository
                .findByUser_UserIdAndSummaryDate(userId, date)
                .orElseGet(() -> createSummary(userId, date));
        List<DailyNutrientTotal> totals = totalRepository
                .findByDailyWellnessSummaryDailySummaryId(summary.getDailySummaryId());
        addAmount(summary, totals, "Calories", "kcal", 1, request.calories(), new BigDecimal("2000"));
        addAmount(summary, totals, "Protein", "g", 2, request.protein(), new BigDecimal("120"));
        addAmount(summary, totals, "Carbohydrates", "g", 3, request.carbs(), new BigDecimal("205"));
        addAmount(summary, totals, "Fat", "g", 4, request.fat(), new BigDecimal("78"));
        addAmount(summary, totals, "Water", "glasses", 5, request.water(), new BigDecimal("8"));
        addAmount(summary, totals, "Fiber", "g", 6, request.fiber(), new BigDecimal("25"));
        addAmount(summary, totals, "Sugar", "g", 7, request.sugar(), new BigDecimal("50"));
        if (request.aiRecommendation() != null && !request.aiRecommendation().isBlank()) {
            String insight = request.aiRecommendation().trim();
            summary.setAiInsightText(insight);
        }
        summary.setUpdatedAt(LocalDateTime.now());
        summaryRepository.save(summary);
    }

    @Transactional
    public void upsertMealPlan(Integer userId, Integer mealPlanId, LocalDate date,
            BigDecimal calories, BigDecimal protein, BigDecimal carbs, BigDecimal fat) {
        upsertSource(userId, date, "MEAL_PLAN", mealPlanId.toString(),
                value(calories), value(protein), value(carbs), value(fat),
                BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO);
    }

    @Transactional
    public void removeMealPlan(Integer userId, Integer mealPlanId) {
        removeSource(userId, "MEAL_PLAN", mealPlanId.toString());
    }

    private void upsertSource(Integer userId, LocalDate date, String rawType, String rawId,
            BigDecimal calories, BigDecimal protein, BigDecimal carbs, BigDecimal fat,
            BigDecimal water, BigDecimal fiber, BigDecimal sugar) {
        String type = sourceType(rawType);
        String sourceId = rawId.trim();
        if (sourceId.isEmpty() || sourceId.length() > 100) {
            throw new IllegalArgumentException("A valid nutrition source ID is required");
        }
        DailyNutritionSourceLog log = sourceLogRepository
                .findByUserUserIdAndSourceTypeAndSourceId(userId, type, sourceId)
                .orElse(null);
        if (log != null && !log.getLogDate().equals(date)) {
            adjust(userId, log.getLogDate(), log.getCalories().negate(), log.getProtein().negate(),
                    log.getCarbs().negate(), log.getFat().negate(), log.getWater().negate(),
                    log.getFiber().negate(), log.getSugar().negate());
            adjust(userId, date, calories, protein, carbs, fat, water, fiber, sugar);
        } else if (log != null) {
            adjust(userId, date, calories.subtract(log.getCalories()), protein.subtract(log.getProtein()),
                    carbs.subtract(log.getCarbs()), fat.subtract(log.getFat()), water.subtract(log.getWater()),
                    fiber.subtract(log.getFiber()), sugar.subtract(log.getSugar()));
        } else {
            log = new DailyNutritionSourceLog();
            log.setUser(userRepository.getReferenceById(userId));
            log.setSourceType(type);
            log.setSourceId(sourceId);
            adjust(userId, date, calories, protein, carbs, fat, water, fiber, sugar);
        }
        log.setLogDate(date);
        log.setCalories(calories);
        log.setProtein(protein);
        log.setCarbs(carbs);
        log.setFat(fat);
        log.setWater(water);
        log.setFiber(fiber);
        log.setSugar(sugar);
        sourceLogRepository.save(log);
    }

    private void removeSource(Integer userId, String rawType, String sourceId) {
        sourceLogRepository.findByUserUserIdAndSourceTypeAndSourceId(
                userId, sourceType(rawType), sourceId).ifPresent(log -> {
                    adjust(userId, log.getLogDate(), log.getCalories().negate(), log.getProtein().negate(),
                            log.getCarbs().negate(), log.getFat().negate(), log.getWater().negate(),
                            log.getFiber().negate(), log.getSugar().negate());
                    sourceLogRepository.delete(log);
                });
    }

    private void adjust(Integer userId, LocalDate date, BigDecimal calories, BigDecimal protein,
            BigDecimal carbs, BigDecimal fat, BigDecimal water, BigDecimal fiber, BigDecimal sugar) {
        DailyWellnessSummary summary = summaryRepository.findByUser_UserIdAndSummaryDate(userId, date)
                .orElseGet(() -> createSummary(userId, date));
        List<DailyNutrientTotal> totals = totalRepository
                .findByDailyWellnessSummaryDailySummaryId(summary.getDailySummaryId());
        addAmount(summary, totals, "Calories", "kcal", 1, calories, new BigDecimal("2000"));
        addAmount(summary, totals, "Protein", "g", 2, protein, new BigDecimal("120"));
        addAmount(summary, totals, "Carbohydrates", "g", 3, carbs, new BigDecimal("205"));
        addAmount(summary, totals, "Fat", "g", 4, fat, new BigDecimal("78"));
        addAmount(summary, totals, "Water", "glasses", 5, water, new BigDecimal("8"));
        addAmount(summary, totals, "Fiber", "g", 6, fiber, new BigDecimal("25"));
        addAmount(summary, totals, "Sugar", "g", 7, sugar, new BigDecimal("50"));
        summary.setUpdatedAt(LocalDateTime.now());
        summaryRepository.save(summary);
    }

    private void updateInsight(Integer userId, LocalDate date, String insight) {
        if (insight == null || insight.isBlank()) return;
        DailyWellnessSummary summary = summaryRepository.findByUser_UserIdAndSummaryDate(userId, date)
                .orElseGet(() -> createSummary(userId, date));
        summary.setAiInsightText(insight.trim());
        summary.setUpdatedAt(LocalDateTime.now());
        summaryRepository.save(summary);
    }

    private boolean hasSource(String type, String id) {
        return hasText(type) && hasText(id);
    }

    private boolean hasText(String value) {
        return value != null && !value.isBlank();
    }

    private String sourceType(String value) {
        String normalized = value == null ? "" : value.trim().toUpperCase(Locale.ROOT);
        if (!List.of("MEAL_PLAN", "AI_SCAN").contains(normalized)) {
            throw new IllegalArgumentException("Invalid nutrition source type");
        }
        return normalized;
    }

    private BigDecimal value(BigDecimal amount) {
        return amount == null ? BigDecimal.ZERO : amount;
    }

    private DailyWellnessSummary createSummary(Integer userId, LocalDate date) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        DailyWellnessSummary summary = new DailyWellnessSummary();
        summary.setUser(user);
        summary.setSummaryDate(date);
        summary.setBalanceStatus("Tracking");
        summary.setCreatedAt(LocalDateTime.now());
        summary.setUpdatedAt(LocalDateTime.now());
        return summaryRepository.saveAndFlush(summary);
    }

    private void addAmount(DailyWellnessSummary summary, List<DailyNutrientTotal> totals,
            String name, String unit, int order, BigDecimal amount, BigDecimal defaultGoal) {
        if (amount == null || amount.signum() == 0)
            return;
        Nutrient nutrient = nutrientRepository.findByNutrientNameIgnoreCase(name)
                .orElseGet(() -> createNutrient(name, unit, order));
        DailyNutrientTotal total = totals.stream()
                .filter(item -> item.getNutrient().getNutrientId().equals(nutrient.getNutrientId()))
                .findFirst().orElseGet(() -> newTotal(summary, nutrient, defaultGoal));
        BigDecimal consumed = total.getConsumedAmount().add(amount).max(BigDecimal.ZERO);
        total.setConsumedAmount(consumed);
        total.setPercentage(total.getConsumedAmount()
                .multiply(new BigDecimal("100"))
                .divide(total.getGoalAmount(), 2, RoundingMode.HALF_UP));
        totalRepository.save(total);
    }

    private Nutrient createNutrient(String name, String unit, int order) {
        Nutrient nutrient = new Nutrient();
        nutrient.setNutrientName(name);
        nutrient.setUnit(unit);
        nutrient.setDisplayOrder(order);
        nutrient.setIsCore(true);
        nutrient.setIsActive(true);
        return nutrientRepository.save(nutrient);
    }

    private DailyNutrientTotal newTotal(DailyWellnessSummary summary, Nutrient nutrient, BigDecimal goal) {
        DailyNutrientTotal total = new DailyNutrientTotal();
        total.setDailyWellnessSummary(summary);
        total.setNutrient(nutrient);
        total.setGoalAmount(goal);
        total.setConsumedAmount(BigDecimal.ZERO);
        total.setPercentage(BigDecimal.ZERO);
        return totalRepository.save(total);
    }
}
