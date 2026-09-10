package com.nhamhealth.nhamhealth_api.web;

import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.redirectedUrl;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.view;

import com.nhamhealth.nhamhealth_api.entity.AiFoodAnalysis;
import com.nhamhealth.nhamhealth_api.entity.DailyWellnessSummary;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.ai.AiFoodAnalysisRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.repository.wellness.DailyWellnessSummaryRepository;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
class LoginPageTests {

  @Autowired private MockMvc mockMvc;

  @Autowired private AiFoodAnalysisRepository aiFoodAnalysisRepository;

  @Autowired private UserRepository userRepository;

  @Autowired private DailyWellnessSummaryRepository dailyWellnessSummaryRepository;

  @Test
  void loginPageIsPublicAndContainsTheLoginForm() throws Exception {
    mockMvc
        .perform(get("/login"))
        .andExpect(status().isOk())
        .andExpect(view().name("login"))
        .andExpect(content().string(containsString("Welcome back")))
        .andExpect(content().string(containsString("name=\"email\"")))
        .andExpect(content().string(containsString("name=\"password\"")))
        .andExpect(content().string(containsString("name=\"_csrf\"")));
  }

  @Test
  void protectedDashboardRouteRedirectsToCustomLoginPage() throws Exception {
    mockMvc
        .perform(get("/dashboard"))
        .andExpect(status().is3xxRedirection())
        .andExpect(redirectedUrl("/login"));
  }

  @Test
  void authenticatedAdminCanRenderFavoritesPage() throws Exception {
    mockMvc
        .perform(get("/admin/favorites").with(user("admin@nhamhealth.local").roles("ADMIN")))
        .andExpect(status().isOk())
        .andExpect(view().name("admin/favorite"));
  }

  @Test
  void authenticatedAdminCanRenderCommunityRecipesPage() throws Exception {
    mockMvc
        .perform(
            get("/admin/community-recipes").with(user("admin@nhamhealth.local").roles("ADMIN")))
        .andExpect(status().isOk())
        .andExpect(view().name("admin/community-recipes"))
        .andExpect(content().string(containsString("Community recipes")));
  }

  @Test
  void authenticatedAdminCanRenderReportManagementPages() throws Exception {
    for (String route :
        new String[] {
          "/admin/reports",
          "/admin/reports/profiles",
          "/admin/reports/posts",
          "/admin/reports/comments",
          "/admin/reports/appeals",
          "/admin/reports/moderation-history"
        }) {
      mockMvc
          .perform(get(route).with(user("admin@nhamhealth.local").roles("ADMIN")))
          .andExpect(status().isOk());
    }
  }

  @Test
  void normalUserCannotAccessReportManagement() throws Exception {
    mockMvc
        .perform(get("/admin/reports").with(user("user@example.com").roles("USER")))
        .andExpect(status().isForbidden());
  }

  @Test
  void removedReviewsPageReturnsNotFound() throws Exception {
    mockMvc
        .perform(get("/admin/reviews").with(user("admin@nhamhealth.local").roles("ADMIN")))
        .andExpect(status().isNotFound());
  }

  @Test
  void mealAdminPageHasEasyEditingAndNoReviewUi() throws Exception {
    mockMvc
        .perform(get("/admin/meals").with(user("admin@nhamhealth.local").roles("ADMIN")))
        .andExpect(status().isOk())
        .andExpect(view().name("admin/meals"))
        .andExpect(content().string(containsString("<th>Manage</th>")))
        .andExpect(content().string(containsString("id=\"mealDescription\"")))
        .andExpect(content().string(not(containsString("Review Count"))))
        .andExpect(content().string(not(containsString("Average Rating"))));
  }

  @Test
  void removedMealLogsPageReturnsNotFound() throws Exception {
    mockMvc
        .perform(get("/admin/meal-logs").with(user("admin@nhamhealth.local").roles("ADMIN")))
        .andExpect(status().isNotFound());
  }

  @Test
  void removedNutrientGoalsPageReturnsNotFound() throws Exception {
    mockMvc
        .perform(get("/admin/nutrient-goals").with(user("admin@nhamhealth.local").roles("ADMIN")))
        .andExpect(status().isNotFound());
  }

  @Test
  void authenticatedAdminCanRenderDailyWellnessPage() throws Exception {
    mockMvc
        .perform(get("/admin/daily-wellness").with(user("admin@nhamhealth.local").roles("ADMIN")))
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
      mockMvc
          .perform(get("/admin/daily-wellness").with(user("admin@nhamhealth.local").roles("ADMIN")))
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
      mockMvc
          .perform(
              get("/admin/ai-food-analyses").with(user("admin@nhamhealth.local").roles("ADMIN")))
          .andExpect(status().isOk())
          .andExpect(view().name("admin/ai-food-analysis"))
          .andExpect(content().string(containsString("Chicken salad")));
    } finally {
      aiFoodAnalysisRepository.deleteById(analysis.getAiFoodAnalysisId());
    }
  }

  @Test
  void authenticatedAdminCanRenderAiFoodSuggestionsPage() throws Exception {
    mockMvc
        .perform(
            get("/admin/ai-food-suggestions").with(user("admin@nhamhealth.local").roles("ADMIN")))
        .andExpect(status().isOk())
        .andExpect(view().name("admin/ai-food-suggestion"))
        .andExpect(content().string(containsString("Learned corrections")))
        .andExpect(content().string(containsString("suggestionDetailsModal")))
        .andExpect(content().string(containsString("Original AI result")));
  }
}
