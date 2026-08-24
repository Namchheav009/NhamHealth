package com.nhamhealth.nhamhealth_api.web;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

import static org.hamcrest.Matchers.containsString;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.redirectedUrl;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.view;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

import com.nhamhealth.nhamhealth_api.entity.AiFoodAnalysis;
import com.nhamhealth.nhamhealth_api.entity.DailyWellnessSummary;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.AiFoodAnalysisRepository;
import com.nhamhealth.nhamhealth_api.repository.DailyWellnessSummaryRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

@SpringBootTest
@AutoConfigureMockMvc
class LoginPageTests {

	@Autowired
	private MockMvc mockMvc;

	@Autowired
	private AiFoodAnalysisRepository aiFoodAnalysisRepository;

	@Autowired
	private UserRepository userRepository;

	@Autowired
	private DailyWellnessSummaryRepository dailyWellnessSummaryRepository;

	@Test
	void loginPageIsPublicAndContainsTheLoginForm() throws Exception {
		mockMvc.perform(get("/login"))
				.andExpect(status().isOk())
				.andExpect(view().name("login"))
				.andExpect(content().string(containsString("Welcome back")))
				.andExpect(content().string(containsString("name=\"email\"")))
				.andExpect(content().string(containsString("name=\"password\"")))
				.andExpect(content().string(containsString("name=\"_csrf\"")));
	}

	@Test
	void protectedDashboardRouteRedirectsToCustomLoginPage() throws Exception {
		mockMvc.perform(get("/dashboard"))
				.andExpect(status().is3xxRedirection())
				.andExpect(redirectedUrl("/login"));
	}

	@Test
	void authenticatedAdminCanRenderFavoritesPage() throws Exception {
		mockMvc.perform(get("/admin/favorites")
					.with(user("admin@nhamhealth.local").roles("ADMIN")))
				.andExpect(status().isOk())
				.andExpect(view().name("admin/favorite"));
	}

	@Test
	void authenticatedAdminCanRenderReviewsPage() throws Exception {
		mockMvc.perform(get("/admin/reviews")
					.with(user("admin@nhamhealth.local").roles("ADMIN")))
				.andExpect(status().isOk())
				.andExpect(view().name("admin/review"));
	}

	@Test
	void authenticatedAdminCanRenderMealLogsPage() throws Exception {
		mockMvc.perform(get("/admin/meal-logs")
					.with(user("admin@nhamhealth.local").roles("ADMIN")))
				.andExpect(status().isOk())
				.andExpect(view().name("admin/meals-log"));
	}

	@Test
	void authenticatedAdminCanRenderNutrientGoalsPage() throws Exception {
		mockMvc.perform(get("/admin/nutrient-goals")
					.with(user("admin@nhamhealth.local").roles("ADMIN")))
				.andExpect(status().isOk())
				.andExpect(view().name("admin/nutrient-goal"));
	}

	@Test
	void authenticatedAdminCanRenderDailyWellnessPage() throws Exception {
		mockMvc.perform(get("/admin/daily-wellness")
					.with(user("admin@nhamhealth.local").roles("ADMIN")))
				.andExpect(status().isOk())
				.andExpect(view().name("admin/daily-wellness"));
	}

	@Test
	void authenticatedAdminCanRenderDailyWellnessPageWithSummaryRelations() throws Exception {
		User admin = userRepository.findByEmailIgnoreCase("admin@nhamhealth.local").orElseThrow();
		DailyWellnessSummary summary = new DailyWellnessSummary();
		summary.setUser(admin);
		summary.setSummaryDate(LocalDate.of(2099, 1, 1));
		summary.setBalanceStatus("Balanced");
		summary.setAiInsightText("Wellness template verification");
		summary.setCreatedAt(LocalDateTime.now());
		summary.setUpdatedAt(LocalDateTime.now());
		summary = dailyWellnessSummaryRepository.saveAndFlush(summary);

		try {
			mockMvc.perform(get("/admin/daily-wellness")
					.with(user("admin@nhamhealth.local").roles("ADMIN")))
					.andExpect(status().isOk())
					.andExpect(view().name("admin/daily-wellness"))
					.andExpect(content().string(containsString("Wellness template verification")));
		} finally {
			dailyWellnessSummaryRepository.deleteById(summary.getDailySummaryId());
		}
	}

	@Test
	void authenticatedAdminCanRenderAiFoodAnalysesPage() throws Exception {
		User admin = userRepository.findByEmailIgnoreCase("admin@nhamhealth.local").orElseThrow();
		AiFoodAnalysis analysis = new AiFoodAnalysis();
		analysis.setUser(admin);
		analysis.setInputText("grilled chicken salad");
		analysis.setDetectedFoodName("Chicken salad");
		analysis.setDetectedServingText("1 bowl");
		analysis.setConfidenceScore(new BigDecimal("0.85"));
		analysis.setStatus("completed");
		analysis.setCreatedAt(LocalDateTime.now());
		analysis = aiFoodAnalysisRepository.saveAndFlush(analysis);

		try {
			mockMvc.perform(get("/admin/ai-food-analyses")
						.with(user("admin@nhamhealth.local").roles("ADMIN")))
					.andExpect(status().isOk())
					.andExpect(view().name("admin/ai-food-analysis"))
					.andExpect(content().string(containsString("Chicken salad")));
		} finally {
			aiFoodAnalysisRepository.deleteById(analysis.getAiFoodAnalysisId());
		}
	}

	@Test
	void authenticatedAdminCanRenderAiFoodSuggestionsPage() throws Exception {
		mockMvc.perform(get("/admin/ai-food-suggestions")
					.with(user("admin@nhamhealth.local").roles("ADMIN")))
				.andExpect(status().isOk())
				.andExpect(view().name("admin/ai-food-suggestion"));
	}
}
