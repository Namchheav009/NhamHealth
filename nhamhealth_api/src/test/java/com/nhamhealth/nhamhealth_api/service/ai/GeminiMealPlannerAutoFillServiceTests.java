package com.nhamhealth.nhamhealth_api.service.ai;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.io.OutputStream;
import java.math.BigDecimal;
import java.net.InetSocketAddress;
import java.time.Duration;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.Test;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.nhamhealth.nhamhealth_api.entity.PlannerMeal;
import com.nhamhealth.nhamhealth_api.service.ai.IbmMealPlannerRecommendationService.AutoFillPlanSynthesis;
import com.nhamhealth.nhamhealth_api.service.ai.IbmMealPlannerRecommendationService.DaySlotSelection;
import com.sun.net.httpserver.HttpServer;

class GeminiMealPlannerAutoFillServiceTests {

    @Test
    void usesGeminiSelectionsAndReportsTheActualModel() throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress(0), 0);
        ObjectMapper mapper = new ObjectMapper();
        server.createContext("/v1beta/models/gemini-primary:generateContent", exchange -> {
            String selectionJson = """
                    {"selections":[{"date":"2026-09-21","slot":"BREAKFAST","mealId":10,"rationale":"Easy balanced breakfast"}]}
                    """;
            byte[] response = mapper.writeValueAsBytes(Map.of(
                    "candidates", List.of(Map.of(
                            "content", Map.of("parts", List.of(Map.of("text", selectionJson)))))));
            exchange.getResponseHeaders().add("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, response.length);
            try (OutputStream output = exchange.getResponseBody()) {
                output.write(response);
            }
        });
        server.start();
        try {
            PlannerMeal meal = meal(10, "Oatmeal and fruit", "Breakfast", 400, 18);
            LocalDate date = LocalDate.of(2026, 9, 21);

            IbmMealPlannerRecommendationService clinical = mock(IbmMealPlannerRecommendationService.class);
            when(clinical.synthesizeClinicalPlan(any(), any(), any(), any(Double.class),
                    any(Double.class), any(), any()))
                    .thenReturn(new AutoFillPlanSynthesis(
                            List.of(new DaySlotSelection(date, "BREAKFAST", meal, "fallback")),
                            "fallback", 400, 0, 0, "clinical-rule-fallback"));

            GeminiMealPlannerAutoFillService service = new GeminiMealPlannerAutoFillService(
                    clinical,
                    "http://localhost:" + server.getAddress().getPort() + "/v1beta",
                    "test-key",
                    "gemini-primary",
                    "gemini-fallback",
                    new GeminiRateLimitGuard(Duration.ofMinutes(1), System::nanoTime));

            AutoFillPlanSynthesis result = service.synthesizeWeeklyPlan(
                    List.of(date),
                    Map.of(date, List.of("BREAKFAST")),
                    List.of(meal),
                    1800,
                    2300,
                    "MAINTAIN_HEALTH",
                    "en");

            assertEquals(1, result.selections().size());
            assertEquals(10, result.selections().getFirst().selectedMeal().getPlannerMealId());
            assertEquals(0.0, result.weeklyPaceKg());
            assertTrue(result.summaryRationale().contains("maintenance"));
            assertTrue(!result.summaryRationale().contains("weight-loss"));
            assertTrue(result.modelUsed().contains("Google Gemini"));
            assertTrue(result.modelUsed().contains("gemini-primary"));
        } finally {
            server.stop(0);
        }
    }

    @Test
    void usesGeminiAiCoachingSummaryWhenProvided() throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress(0), 0);
        ObjectMapper mapper = new ObjectMapper();
        server.createContext("/v1beta/models/gemini-primary:generateContent", exchange -> {
            String selectionJson = """
                    {
                      "summary": "សួស្តី! ផែនការហូបចុកប្រចាំសប្តាហ៍នេះត្រូវបានរៀបចំឡើងយ៉ាងពិសេស ដើម្បីជួយអ្នកសម្រកទម្ងន់។",
                      "selections":[{"date":"2026-09-21","slot":"BREAKFAST","mealId":10,"rationale":"អាហារពេលព្រឹកសម្បូរជាតិប្រូតេអ៊ីន"}]
                    }
                    """;
            byte[] response = mapper.writeValueAsBytes(Map.of(
                    "candidates", List.of(Map.of(
                            "content", Map.of("parts", List.of(Map.of("text", selectionJson)))))));
            exchange.getResponseHeaders().add("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, response.length);
            try (OutputStream output = exchange.getResponseBody()) {
                output.write(response);
            }
        });
        server.start();
        try {
            PlannerMeal meal = meal(10, "Oatmeal", "Breakfast", 350, 18);
            LocalDate date = LocalDate.of(2026, 9, 21);

            IbmMealPlannerRecommendationService clinical = mock(IbmMealPlannerRecommendationService.class);
            when(clinical.synthesizeClinicalPlan(any(), any(), any(), any(Double.class),
                    any(Double.class), any(), any()))
                    .thenReturn(new AutoFillPlanSynthesis(
                            List.of(new DaySlotSelection(date, "BREAKFAST", meal, "fallback")),
                            "fallback", 350, 0, 0, "clinical-rule-fallback"));

            GeminiMealPlannerAutoFillService service = new GeminiMealPlannerAutoFillService(
                    clinical,
                    "http://localhost:" + server.getAddress().getPort() + "/v1beta",
                    "test-key",
                    "gemini-primary",
                    "gemini-fallback",
                    new GeminiRateLimitGuard(Duration.ofMinutes(1), System::nanoTime));

            AutoFillPlanSynthesis result = service.synthesizeWeeklyPlan(
                    List.of(date),
                    Map.of(date, List.of("BREAKFAST")),
                    List.of(meal),
                    1800,
                    2300,
                    "LOSE_WEIGHT",
                    "km");

            assertEquals(1, result.selections().size());
            assertEquals("សួស្តី! ផែនការហូបចុកប្រចាំសប្តាហ៍នេះត្រូវបានរៀបចំឡើងយ៉ាងពិសេស ដើម្បីជួយអ្នកសម្រកទម្ងន់។",
                    result.summaryRationale());
            assertTrue(result.modelUsed().contains("Google Gemini"));
        } finally {
            server.stop(0);
        }
    }

    @Test
    void rejectsDuplicateGeminiMealsAndUsesTheVariedClinicalPlan() throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress(0), 0);
        ObjectMapper mapper = new ObjectMapper();
        var duplicateHandler = (com.sun.net.httpserver.HttpHandler) exchange -> {
            String selectionJson = """
                    {"selections":[
                      {"date":"2026-09-21","slot":"BREAKFAST","mealId":10,"rationale":"first"},
                      {"date":"2026-09-21","slot":"LUNCH","mealId":10,"rationale":"duplicate"}
                    ]}
                    """;
            byte[] response = mapper.writeValueAsBytes(Map.of(
                    "candidates", List.of(Map.of(
                            "content", Map.of("parts", List.of(Map.of("text", selectionJson)))))));
            exchange.getResponseHeaders().add("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, response.length);
            try (OutputStream output = exchange.getResponseBody()) {
                output.write(response);
            }
        };
        server.createContext("/v1beta/models/gemini-primary:generateContent", duplicateHandler);
        server.createContext("/v1beta/models/gemini-fallback:generateContent", duplicateHandler);
        server.start();
        try {
            PlannerMeal breakfast = meal(10, "Oatmeal", "Breakfast", 350, 18);
            PlannerMeal lunch = meal(11, "Chicken bowl", "Lunch", 500, 35);
            LocalDate date = LocalDate.of(2026, 9, 21);
            AutoFillPlanSynthesis clinicalPlan = new AutoFillPlanSynthesis(
                    List.of(
                            new DaySlotSelection(date, "BREAKFAST", breakfast, "fallback breakfast"),
                            new DaySlotSelection(date, "LUNCH", lunch, "fallback lunch")),
                    "varied fallback", 850, 0, 0, "clinical-rule-fallback");

            IbmMealPlannerRecommendationService clinical = mock(IbmMealPlannerRecommendationService.class);
            when(clinical.synthesizeClinicalPlan(any(), any(), any(), any(Double.class),
                    any(Double.class), any(), any()))
                    .thenReturn(clinicalPlan);

            GeminiMealPlannerAutoFillService service = new GeminiMealPlannerAutoFillService(
                    clinical,
                    "http://localhost:" + server.getAddress().getPort() + "/v1beta",
                    "test-key",
                    "gemini-primary",
                    "gemini-fallback",
                    new GeminiRateLimitGuard(Duration.ofMinutes(1), System::nanoTime));

            AutoFillPlanSynthesis result = service.synthesizeWeeklyPlan(
                    List.of(date),
                    Map.of(date, List.of("BREAKFAST", "LUNCH")),
                    List.of(breakfast, lunch),
                    1800,
                    2200,
                    "MAINTAIN_HEALTH",
                    "en");

            assertEquals("clinical-rule-fallback", result.modelUsed());
            assertEquals(2, result.selections().stream()
                    .map(selection -> selection.selectedMeal().getPlannerMealId())
                    .collect(java.util.stream.Collectors.toSet()).size());
        } finally {
            server.stop(0);
        }
    }

    @Test
    void recommendsMealToAddWithGeminiAndProvidesKhmerRationale() throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress(0), 0);
        ObjectMapper mapper = new ObjectMapper();
        server.createContext("/v1beta/models/gemini-primary:generateContent", exchange -> {
            String json = """
                    {
                      "recommendedMealId": 10,
                      "alternativeMealIds": [20],
                      "rationale": "អាហារនេះសម្បូរប្រូតេអ៊ីនល្អសម្រាប់អាហារពេលព្រឹក"
                    }
                    """;
            byte[] response = mapper.writeValueAsBytes(Map.of(
                    "candidates", List.of(Map.of(
                            "content", Map.of("parts", List.of(Map.of("text", json)))))));
            exchange.getResponseHeaders().add("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, response.length);
            try (OutputStream output = exchange.getResponseBody()) {
                output.write(response);
            }
        });
        server.start();
        try {
            PlannerMeal meal1 = meal(10, "Eggs & toast", "Breakfast", 380, 22);
            PlannerMeal meal2 = meal(20, "Oatmeal", "Breakfast", 320, 14);

            IbmMealPlannerRecommendationService clinical = mock(IbmMealPlannerRecommendationService.class);
            GeminiMealPlannerAutoFillService service = new GeminiMealPlannerAutoFillService(
                    clinical,
                    "http://localhost:" + server.getAddress().getPort() + "/v1beta",
                    "test-key",
                    "gemini-primary",
                    "gemini-fallback",
                    new GeminiRateLimitGuard(Duration.ofMinutes(1), System::nanoTime));

            var result = service.recommendMeal(
                    LocalDate.of(2026, 9, 23),
                    "BREAKFAST",
                    null,
                    List.of(meal1, meal2),
                    1800,
                    2200,
                    "LOSE_WEIGHT",
                    "km",
                    "ADD");

            assertNotNull(result);
            assertEquals(10, result.recommendedMeal().getPlannerMealId());
            assertEquals(1, result.alternatives().size());
            assertEquals(20, result.alternatives().getFirst().getPlannerMealId());
            assertEquals("អាហារនេះសម្បូរប្រូតេអ៊ីនល្អសម្រាប់អាហារពេលព្រឹក", result.aiRationale());
            assertEquals("ADD", result.actionType());
            assertTrue(result.modelUsed().contains("Google Gemini"));
        } finally {
            server.stop(0);
        }
    }

    @Test
    void recommendsMealToSwapExcludingCurrentMeal() throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress(0), 0);
        ObjectMapper mapper = new ObjectMapper();
        server.createContext("/v1beta/models/gemini-primary:generateContent", exchange -> {
            String json = """
                    {
                      "recommendedMealId": 20,
                      "alternativeMealIds": [],
                      "rationale": "ជម្រើសជំនួសដ៏ល្អសម្បូរជាតិសរសៃ និងកាឡូរីសមរម្យ"
                    }
                    """;
            byte[] response = mapper.writeValueAsBytes(Map.of(
                    "candidates", List.of(Map.of(
                            "content", Map.of("parts", List.of(Map.of("text", json)))))));
            exchange.getResponseHeaders().add("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, response.length);
            try (OutputStream output = exchange.getResponseBody()) {
                output.write(response);
            }
        });
        server.start();
        try {
            PlannerMeal current = meal(10, "Fried Rice", "Lunch", 650, 15);
            PlannerMeal alt = meal(20, "Steamed Fish & Veggies", "Lunch", 450, 35);

            IbmMealPlannerRecommendationService clinical = mock(IbmMealPlannerRecommendationService.class);
            GeminiMealPlannerAutoFillService service = new GeminiMealPlannerAutoFillService(
                    clinical,
                    "http://localhost:" + server.getAddress().getPort() + "/v1beta",
                    "test-key",
                    "gemini-primary",
                    "gemini-fallback",
                    new GeminiRateLimitGuard(Duration.ofMinutes(1), System::nanoTime));

            var result = service.recommendMeal(
                    LocalDate.of(2026, 9, 23),
                    "LUNCH",
                    current,
                    List.of(current, alt),
                    1800,
                    2200,
                    "LOSE_WEIGHT",
                    "km",
                    "SWAP");

            assertNotNull(result);
            assertEquals(20, result.recommendedMeal().getPlannerMealId());
            assertEquals("ជម្រើសជំនួសដ៏ល្អសម្បូរជាតិសរសៃ និងកាឡូរីសមរម្យ", result.aiRationale());
            assertEquals("SWAP", result.actionType());
        } finally {
            server.stop(0);
        }
    }

    private static PlannerMeal meal(int id, String name, String category, int calories, int protein) {
        PlannerMeal meal = new PlannerMeal();
        meal.setPlannerMealId(id);
        meal.setNameEn(name);
        meal.setCategoryEn(category);
        meal.setCalories(BigDecimal.valueOf(calories));
        meal.setProteinGrams(BigDecimal.valueOf(protein));
        meal.setCarbsGrams(new BigDecimal("40"));
        meal.setFatGrams(new BigDecimal("12"));
        meal.setActive(true);
        return meal;
    }
}
