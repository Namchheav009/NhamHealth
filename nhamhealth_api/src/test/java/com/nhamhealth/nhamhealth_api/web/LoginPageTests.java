package com.nhamhealth.nhamhealth_api.web;

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

@SpringBootTest
@AutoConfigureMockMvc
class LoginPageTests {

	@Autowired
	private MockMvc mockMvc;

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
	void authenticatedAdminCanRenderAiFoodAnalysesPage() throws Exception {
		mockMvc.perform(get("/admin/ai-food-analyses")
					.with(user("admin@nhamhealth.local").roles("ADMIN")))
				.andExpect(status().isOk())
				.andExpect(view().name("admin/ai-food-analysis"));
	}

	@Test
	void authenticatedAdminCanRenderAiFoodSuggestionsPage() throws Exception {
		mockMvc.perform(get("/admin/ai-food-suggestions")
					.with(user("admin@nhamhealth.local").roles("ADMIN")))
				.andExpect(status().isOk())
				.andExpect(view().name("admin/ai-food-suggestion"));
	}
}
