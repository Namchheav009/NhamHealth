package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.DailyNutrientTotal;

public interface DailyNutrientTotalRepository extends JpaRepository<DailyNutrientTotal, Integer> {
    void deleteByDailyWellnessSummaryDailySummaryId(Integer summaryId);

    List<DailyNutrientTotal> findByDailyWellnessSummaryDailySummaryId(Integer summaryId);
}
