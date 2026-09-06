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

    private ProfileDashboardResponse.Progress progress(String current, String goal) {
        return new ProfileDashboardResponse.Progress(new BigDecimal(current), new BigDecimal(goal));
    }
}
