package com.nhamhealth.nhamhealth_api.repository.wellness;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.DailyNutritionSourceLog;

public interface DailyNutritionSourceLogRepository extends JpaRepository<DailyNutritionSourceLog, Integer> {
    Optional<DailyNutritionSourceLog> findByUserUserIdAndSourceTypeAndSourceId(
            Integer userId, String sourceType, String sourceId);
}
