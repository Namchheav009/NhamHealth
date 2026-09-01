package com.nhamhealth.nhamhealth_api.repository.wellness;

import java.util.List;
import java.time.LocalDate;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.nhamhealth.nhamhealth_api.entity.DailyNutrientTotal;

public interface DailyNutrientTotalRepository extends JpaRepository<DailyNutrientTotal, Integer> {
    void deleteByDailyWellnessSummaryDailySummaryId(Integer summaryId);

    void deleteByNutrientNutrientId(Integer nutrientId);

    @EntityGraph(attributePaths = "nutrient")
    List<DailyNutrientTotal> findByDailyWellnessSummaryDailySummaryId(Integer summaryId);

    @Query("""
            select total.nutrient.nutrientName, total.nutrient.unit,
                   sum(total.consumedAmount), sum(total.goalAmount), count(total)
            from DailyNutrientTotal total
            where total.dailyWellnessSummary.summaryDate = :summaryDate
            group by total.nutrient.nutrientName, total.nutrient.unit
            """)
    List<Object[]> summarizeBySummaryDate(@Param("summaryDate") LocalDate summaryDate);
}
