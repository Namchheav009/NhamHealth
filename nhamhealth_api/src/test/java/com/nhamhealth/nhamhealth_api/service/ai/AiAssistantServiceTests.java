package com.nhamhealth.nhamhealth_api.service.ai;

import java.math.BigDecimal;
import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;
import org.junit.jupiter.api.Test;

import com.nhamhealth.nhamhealth_api.dto.response.ProfileDashboardResponse;

class AiAssistantServiceTests {

    @Test
    void fallbackExplainsTheNutritionDashboardWhenTheProviderIsUnavailable() {
        ProfileDashboardResponse dashboard = new ProfileDashboardResponse(
                1, "user@example.com", "Nham", null, null, null, false,
                null, null, null, null, null,
                progress("650", "2000"), progress("28", "120"), progress("90", "205"), progress("18", "78"),
                progress("3", "8"), progress("9", "25"), progress("12", "50"), null);

        String reply = AiAssistantService.fallbackReply(
                dashboard, LocalDate.of(2026, 8, 31), "Explain my nutrition dashboard");

        assertThat(reply)
                .contains("Calories: 650 / 2000")
                .contains("Protein: 28 / 120")
                .contains("Water: 3 / 8")
                .doesNotContain("unavailable");
    }

    @Test
    void rejectsQuestionsOutsideTheNhamHealthScopeInEnglish() {
        String reply = AiAssistantService.outOfScopeReply("Who won the election?");

        assertThat(reply)
                .contains("limited to food, drinks")
                .contains("NhamHealth");
        assertThat(AiAssistantService.isSupportedMessage("Who won the election?"))
                .isFalse();
    }

    @Test
    void rejectsQuestionsOutsideTheNhamHealthScopeInKhmer() {
        String reply = AiAssistantService.outOfScopeReply("តើអ្នកអាចសរសេរកូដឱ្យខ្ញុំបានទេ?");

        assertThat(reply)
                .contains("NhamHealth AI")
                .contains("ម្ហូប")
                .contains("ប៉ុណ្ណោះ");
    }

    @Test
    void acceptsDynamicFoodDrinkAndAppQuestions() {
        assertThat(AiAssistantService.isSupportedMessage("Is iced coffee high in sugar?"))
                .isTrue();
        assertThat(AiAssistantService.isSupportedMessage("ម្ហូបនេះមានប្រូតេអ៊ីនប៉ុន្មាន?"))
                .isTrue();
        assertThat(AiAssistantService.isSupportedMessage("How do I use the meal planner?"))
                .isTrue();
        assertThat(AiAssistantService.isSupportedMessage("How do I edit my account?"))
                .isTrue();
        assertThat(AiAssistantService.isSupportedMessage("តើខ្ញុំកែប្រែគណនីនៅកន្លែងណា?"))
                .isTrue();
    }

    @Test
    void suggestsSafeCoreFeatureActionsFromTheUsersQuestion() {
        assertThat(AiAssistantService.suggestedActions(
                "How can I scan my food and check Daily Wellness?"))
                .containsExactly("scan_food", "daily_wellness");
        assertThat(AiAssistantService.suggestedActions(
                "ខ្ញុំចង់បើកគម្រោងអាហារ"))
                .containsExactly("meal_planner");
        assertThat(AiAssistantService.suggestedActions("Tell me a joke"))
                .isEmpty();
    }

    private ProfileDashboardResponse.Progress progress(String current, String goal) {
        return new ProfileDashboardResponse.Progress(new BigDecimal(current), new BigDecimal(goal));
    }
}
