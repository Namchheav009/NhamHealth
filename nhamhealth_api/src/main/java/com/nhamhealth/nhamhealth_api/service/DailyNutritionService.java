package com.nhamhealth.nhamhealth_api.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.dto.request.DailyNutritionUpdateRequest;
import com.nhamhealth.nhamhealth_api.entity.DailyNutrientTotal;
import com.nhamhealth.nhamhealth_api.entity.DailyWellnessSummary;
import com.nhamhealth.nhamhealth_api.entity.Nutrient;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.DailyNutrientTotalRepository;
import com.nhamhealth.nhamhealth_api.repository.DailyWellnessSummaryRepository;
import com.nhamhealth.nhamhealth_api.repository.NutrientRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

@Service
public class DailyNutritionService {
    private final UserRepository userRepository;
    private final DailyWellnessSummaryRepository summaryRepository;
    private final DailyNutrientTotalRepository totalRepository;
    private final NutrientRepository nutrientRepository;

    public DailyNutritionService(UserRepository userRepository,
            DailyWellnessSummaryRepository summaryRepository,
            DailyNutrientTotalRepository totalRepository,
            NutrientRepository nutrientRepository) {
        this.userRepository = userRepository;
        this.summaryRepository = summaryRepository;
        this.totalRepository = totalRepository;
        this.nutrientRepository = nutrientRepository;
    }

    @Transactional
    public void add(Integer userId, DailyNutritionUpdateRequest request) {
        LocalDate date = request.date() == null ? LocalDate.now() : request.date();
        DailyWellnessSummary summary = summaryRepository
                .findByUser_UserIdAndSummaryDate(userId, date)
                .orElseGet(() -> createSummary(userId, date));
        List<DailyNutrientTotal> totals = totalRepository
                .findByDailyWellnessSummaryDailySummaryId(summary.getDailySummaryId());
        addAmount(summary, totals, "Calories", "kcal", 1, request.calories(), new BigDecimal("2000"));
        addAmount(summary, totals, "Protein", "g", 2, request.protein(), new BigDecimal("120"));
        addAmount(summary, totals, "Fat", "g", 3, request.fat(), new BigDecimal("78"));
        addAmount(summary, totals, "Water", "glasses", 4, request.water(), new BigDecimal("8"));
        addAmount(summary, totals, "Fiber", "g", 5, request.fiber(), new BigDecimal("25"));
        addAmount(summary, totals, "Sugar", "g", 6, request.sugar(), new BigDecimal("50"));
        if (request.aiRecommendation() != null && !request.aiRecommendation().isBlank()) {
            String insight = request.aiRecommendation().trim();
            summary.setAiInsightText(insight);
        }
        summary.setUpdatedAt(LocalDateTime.now());
        summaryRepository.save(summary);
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
        if (amount == null || amount.signum() == 0) return;
        Nutrient nutrient = nutrientRepository.findByNutrientNameIgnoreCase(name)
                .orElseGet(() -> createNutrient(name, unit, order));
        DailyNutrientTotal total = totals.stream()
                .filter(item -> item.getNutrient().getNutrientId().equals(nutrient.getNutrientId()))
                .findFirst().orElseGet(() -> newTotal(summary, nutrient, defaultGoal));
        total.setConsumedAmount(total.getConsumedAmount().add(amount));
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
        total.setConsumedAmount(BigDecimal.ZERO);
        total.setGoalAmount(goal);
        total.setPercentage(BigDecimal.ZERO);
        return total;
    }
}
