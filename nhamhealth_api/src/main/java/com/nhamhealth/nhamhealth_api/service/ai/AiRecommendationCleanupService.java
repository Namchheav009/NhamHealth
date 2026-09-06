package com.nhamhealth.nhamhealth_api.service.ai;

import java.time.LocalDateTime;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.repository.ai.AiRecommendationItemRepository;
import com.nhamhealth.nhamhealth_api.repository.ai.AiRecommendationRepository;

@Service
@EnableScheduling
public class AiRecommendationCleanupService {
    private final AiRecommendationRepository recommendations;
    private final AiRecommendationItemRepository items;
    private final long retentionMinutes;

    public AiRecommendationCleanupService(AiRecommendationRepository recommendations,
            AiRecommendationItemRepository items,
            @Value("${app.ai.recommendation.retention-minutes:21}") long retentionMinutes) {
        if (retentionMinutes <= 0) {
            throw new IllegalArgumentException("Recommendation retention must be positive");
        }
        this.recommendations = recommendations;
        this.items = items;
        this.retentionMinutes = retentionMinutes;
    }

    @Scheduled(fixedDelayString = "${app.ai.recommendation.cleanup-interval-ms:60000}")
    @Transactional
    public void deleteExpiredRecommendations() {
        LocalDateTime cutoff = LocalDateTime.now().minusMinutes(retentionMinutes);
        // Delete children first to respect the foreign key, using one atomic transaction.
        items.deleteExpired(cutoff);
        recommendations.deleteExpired(cutoff);
    }
}
