package com.nhamhealth.nhamhealth_api.controller.api;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.oauth2.jwt.Jwt;

import com.nhamhealth.nhamhealth_api.dto.response.RecommendedMealResponse;
import com.nhamhealth.nhamhealth_api.repository.ai.AiRecommendationItemRepository;
import com.nhamhealth.nhamhealth_api.repository.ai.AiRecommendationRepository;
import com.nhamhealth.nhamhealth_api.service.ai.AiMealRecommendationService;

class AiRecommendationApiControllerTests {

    @Test
    void generateReturnsEmptyListWhenNoPublishedMealsExist() {
        AiRecommendationRepository recommendationRepository = mock(AiRecommendationRepository.class);
        AiRecommendationItemRepository itemRepository = mock(AiRecommendationItemRepository.class);
        AiMealRecommendationService recommendationService = mock(AiMealRecommendationService.class);
        Jwt jwt = mock(Jwt.class);
        when(jwt.getClaim("userId")).thenReturn(7);
        when(recommendationService.generate(7, null, true)).thenReturn(Optional.empty());

        AiRecommendationApiController controller = new AiRecommendationApiController(
                recommendationRepository, itemRepository, recommendationService);

        ResponseEntity<List<RecommendedMealResponse>> response =
                controller.generateRecommendedMeals(jwt, null, true);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().isEmpty());
        verify(recommendationService).generate(7, null, true);
        verifyNoInteractions(itemRepository);
    }
}
