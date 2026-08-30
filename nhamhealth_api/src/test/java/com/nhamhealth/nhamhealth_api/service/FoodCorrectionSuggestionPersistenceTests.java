package com.nhamhealth.nhamhealth_api.service;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.dto.request.AiFoodFeedbackRequest;
import com.nhamhealth.nhamhealth_api.entity.AiFoodAnalysis;
import com.nhamhealth.nhamhealth_api.entity.Role;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.AiFoodAnalysisRepository;
import com.nhamhealth.nhamhealth_api.repository.AiFoodSuggestionRepository;
import com.nhamhealth.nhamhealth_api.repository.RoleRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
class FoodCorrectionSuggestionPersistenceTests {
    @Autowired private FoodCorrectionSuggestionService correctionService;
    @Autowired private AiFoodSuggestionRepository suggestionRepository;
    @Autowired private AiFoodAnalysisRepository analysisRepository;
    @Autowired private UserRepository userRepository;
    @Autowired private RoleRepository roleRepository;

    @Test
    void persistsAndQueriesALearnedCorrectionThroughJpa() {
        Role role = roleRepository.findByRoleNameIgnoreCase("USER")
                .orElseGet(() -> {
                    Role value = new Role();
                    value.setRoleName("USER");
                    value.setDescription("Test user");
                    return roleRepository.save(value);
                });
        User user = new User();
        user.setRole(role);
        user.setEmail("correction-" + UUID.randomUUID() + "@example.com");
        user.setPasswordHash("test-only");
        user.setStatus("ACTIVE");
        user.setIsVerified(true);
        user = userRepository.save(user);

        AiFoodAnalysis analysis = new AiFoodAnalysis();
        analysis.setUser(user);
        analysis.setInputText("drink.jpg");
        analysis.setDetectedFoodName("Unknown tea");
        analysis.setDetectedServingText("1 serving");
        analysis.setStatus("NEEDS_CONFIRMATION");
        analysis.setCreatedAt(LocalDateTime.now());
        analysis = analysisRepository.saveAndFlush(analysis);
        Integer analysisId = analysis.getAiFoodAnalysisId();

        correctionService.recordCorrection(analysis, new AiFoodFeedbackRequest(
                false, "Thai Iced Tea", BigDecimal.valueOf(350), "ml"));
        suggestionRepository.flush();

        assertEquals(1, suggestionRepository
                .findAllBySuggestionTypeIgnoreCaseOrderByAiFoodSuggestionIdDesc(
                        FoodCorrectionSuggestionService.SUGGESTION_TYPE)
                .stream()
                .filter(value -> value.getAiFoodAnalysis().getAiFoodAnalysisId()
                        .equals(analysisId))
                .count());
        assertEquals(Optional.of("Thai Iced Tea"),
                correctionService.findLearnedCorrection("unknown teas"));
    }
}
