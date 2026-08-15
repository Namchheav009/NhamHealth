package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.DailyWellnessSummary;

public interface DailyWellnessSummaryRepository extends JpaRepository<DailyWellnessSummary, Integer> {

    List<DailyWellnessSummary> findAllByOrderBySummaryDateDesc();

    boolean existsByUserUserIdAndSummaryDate(Integer userId, java.time.LocalDate summaryDate);

    Optional<DailyWellnessSummary> findByUser_UserIdAndSummaryDate(
            Integer userId,
            java.time.LocalDate summaryDate);
}
