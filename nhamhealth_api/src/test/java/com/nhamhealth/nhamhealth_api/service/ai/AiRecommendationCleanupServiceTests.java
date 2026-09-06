package com.nhamhealth.nhamhealth_api.service.ai;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

import java.time.LocalDateTime;

import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import com.nhamhealth.nhamhealth_api.repository.ai.AiRecommendationItemRepository;
import com.nhamhealth.nhamhealth_api.repository.ai.AiRecommendationRepository;

class AiRecommendationCleanupServiceTests {
    private final AiRecommendationRepository recommendations = mock(AiRecommendationRepository.class);
    private final AiRecommendationItemRepository items = mock(AiRecommendationItemRepository.class);

    @Test
    void deletesChildrenBeforeParentsWithTheSameTwentyOneMinuteCutoff() {
        LocalDateTime earliest = LocalDateTime.now().minusMinutes(21);
        new AiRecommendationCleanupService(recommendations, items, 21).deleteExpiredRecommendations();
        LocalDateTime latest = LocalDateTime.now().minusMinutes(21);

        var order = inOrder(items, recommendations);
        var cutoff = ArgumentCaptor.forClass(LocalDateTime.class);
        order.verify(items).deleteExpired(cutoff.capture());
        order.verify(recommendations).deleteExpired(cutoff.getValue());
        assertFalse(cutoff.getValue().isBefore(earliest));
        assertFalse(cutoff.getValue().isAfter(latest));
    }

    @Test
    void doesNotDeleteParentsWhenChildDeletionFails() {
        when(items.deleteExpired(any())).thenThrow(new IllegalStateException("database failure"));
        var service = new AiRecommendationCleanupService(recommendations, items, 21);
        assertThrows(IllegalStateException.class, service::deleteExpiredRecommendations);
        verifyNoInteractions(recommendations);
    }

    @Test
    void rejectsNonPositiveRetention() {
        assertThrows(IllegalArgumentException.class,
                () -> new AiRecommendationCleanupService(recommendations, items, 0));
    }
}
