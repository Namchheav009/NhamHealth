package com.nhamhealth.nhamhealth_api.service;

import java.util.Base64;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.server.ResponseStatusException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.nhamhealth.nhamhealth_api.dto.response.AiFoodAnalysisResponse;

import static org.springframework.http.HttpStatus.BAD_GATEWAY;
import static org.springframework.http.HttpStatus.SERVICE_UNAVAILABLE;

@Service
public class NvidiaFoodVisionService {
    private static final Logger log = LoggerFactory.getLogger(NvidiaFoodVisionService.class);
    private static final String PROMPT = """
            Analyze only the food or drink visible in this image. First assess image quality,
            separate the main dish from sides and drinks, identify preparation method, and estimate
            portion using visible plates, bowls, utensils, packaging, or hand-scale cues. Do not
            assume hidden ingredients. Calibrate confidence: 0.85+ only for a clear, unambiguous
            dish and portion; 0.60-0.84 for plausible ambiguity; below 0.60 for unclear or mixed food.
            Cross-check calories against protein, carbs, and fat before responding.
            Return JSON only with exactly these fields:
            name (specific food or drink name), analysis (one concise sentence describing visible
            ingredients, preparation style, portion clues, and uncertainty), confidence (0 to 1),
            calories, protein, carbs, fat, sugar (numbers),
            servingSize (number), servingUnit (string), recommendationTitle (string), and
            recommendation (one short, specific action based on the estimated macros). If no food or drink is visible, use name
            \"Unknown food\", confidence 0, and zero nutrition. Estimates are not medical advice.
            For visible food, calories, protein, carbs, fat, servingSize, recommendationTitle,
            and recommendation must not be missing. Example shape:
            {\"name\":\"Hamburger\",\"analysis\":\"A beef patty in a bun with vegetables; portion appears to be one burger.\",\"confidence\":0.8,\"calories\":350,\"protein\":20,
            \"carbs\":30,\"fat\":17,\"sugar\":6,\"servingSize\":1,\"servingUnit\":\"burger\",
            \"recommendationTitle\":\"Balance the meal\",\"recommendation\":\"Add vegetables.\"}
            """;

    private final RestClient client;
    private final ObjectMapper mapper;
    private final String apiKey;
    private final String model;
    private final String nutritionModel;

    public NvidiaFoodVisionService(
            @Value("${app.ai.nvidia.base-url:https://integrate.api.nvidia.com/v1}") String baseUrl,
            @Value("${app.ai.nvidia.api-key:}") String apiKey,
            @Value("${app.ai.nvidia.model:nvidia/llama-3.1-nemotron-nano-vl-8b-v1}") String model,
            @Value("${app.ai.nvidia.nutrition-model:nvidia/nemotron-3-nano-30b-a3b}") String nutritionModel) {
        this.mapper = new ObjectMapper();
        this.apiKey = apiKey;
        this.model = model;
        this.nutritionModel = nutritionModel;
        this.client = RestClient.builder().baseUrl(baseUrl).build();
    }

    public AiFoodAnalysisResponse analyze(byte[] image, String contentType) {
        if (apiKey == null || apiKey.isBlank()) {
            throw new ResponseStatusException(SERVICE_UNAVAILABLE,
                    "NVIDIA_API_KEY is not configured on the API server.");
        }
        String mime = contentType != null && contentType.startsWith("image/")
                ? contentType : MediaType.IMAGE_JPEG_VALUE;
        String dataUrl = "data:" + mime + ";base64," + Base64.getEncoder().encodeToString(image);
        Map<String, Object> body = Map.of(
                "model", model,
                "temperature", 0.1,
                "max_tokens", 500,
                "messages", List.of(Map.of(
                        "role", "user",
                        "content", List.of(
                                Map.of("type", "image_url", "image_url", Map.of("url", dataUrl)),
                                Map.of("type", "text", "text", PROMPT)))));
        try {
            String responseBody = requestWithRetry(body);
            JsonNode response = mapper.readTree(responseBody);
            String content = response.path("choices").path(0).path("message").path("content").asText();
            String json = content.replaceFirst("(?s)^\\s*```(?:json)?\\s*", "")
                    .replaceFirst("(?s)\\s*```\\s*$", "").trim();
            AiFoodAnalysisResponse result = mapper.readValue(json, AiFoodAnalysisResponse.class);
            if (!isUnknown(result) && !NutritionEstimateValidator.isPlausible(result)) {
                log.info("Vision nutrition estimate for '{}' failed validation; running nutrition pass", result.name());
                AiFoodAnalysisResponse nutrition = estimateNutrition(
                        result.name(), result.servingSize(), result.servingUnit());
                result = mergeVisionAndNutrition(result, nutrition);
            }
            if (!isUnknown(result)
                    && (!NutritionEstimateValidator.isPlausible(result)
                    || result.recommendation() == null || result.recommendation().isBlank())) {
                throw new IllegalStateException("NVIDIA returned implausible or incomplete nutrition data.");
            }
            return result;
        } catch (ResponseStatusException error) {
            throw error;
        } catch (Exception error) {
            throw new ResponseStatusException(BAD_GATEWAY,
                    "The NVIDIA food vision service could not analyze this image.", error);
        }
    }

    private boolean isUnknown(AiFoodAnalysisResponse result) {
        return result.name() == null || "Unknown food".equalsIgnoreCase(result.name().trim());
    }

    private AiFoodAnalysisResponse mergeVisionAndNutrition(
            AiFoodAnalysisResponse vision, AiFoodAnalysisResponse nutrition) {
        return new AiFoodAnalysisResponse(
                vision.name(),
                vision.analysis(),
                Math.clamp(vision.confidence(), 0, 1),
                nutrition.calories(),
                nutrition.protein(),
                nutrition.carbs(),
                nutrition.fat(),
                nutrition.sugar(),
                vision.servingSize() > 0 ? vision.servingSize() : nutrition.servingSize(),
                vision.servingUnit() == null || vision.servingUnit().isBlank()
                        ? nutrition.servingUnit() : vision.servingUnit(),
                nutrition.recommendationTitle(),
                nutrition.recommendation(),
                false, 0, false, null, null, null);
    }

    private String requestWithRetry(Map<String, Object> body) {
        RestClientResponseException lastError = null;
        for (int attempt = 1; attempt <= 2; attempt++) {
            try {
                return client.post()
                        .uri("/chat/completions")
                        .header("Authorization", "Bearer " + apiKey)
                        .header("Accept", MediaType.APPLICATION_JSON_VALUE)
                        .contentType(MediaType.APPLICATION_JSON)
                        .body(body)
                        .retrieve()
                        .body(String.class);
            } catch (RestClientResponseException error) {
                lastError = error;
                int status = error.getStatusCode().value();
                if (attempt == 2 || (status != 502 && status != 503 && status != 504)) {
                    throw error;
                }
                log.warn("NVIDIA vision request returned HTTP {}; retrying once", status);
                try {
                    Thread.sleep(350);
                } catch (InterruptedException interrupted) {
                    Thread.currentThread().interrupt();
                    throw error;
                }
            }
        }
        throw lastError;
    }

    private AiFoodAnalysisResponse estimateNutrition(String name, double servingSize, String servingUnit)
            throws Exception {
        String prompt = """
                Estimate realistic nutrition for the described food portion. Return JSON only with
                exactly these keys: name, analysis, confidence, calories, protein, carbs, fat, sugar,
                servingSize, servingUnit, recommendationTitle, recommendation. All numeric fields
                must be numbers and calories must be greater than zero. Keep recommendation under
                20 words. Food: %s. Portion: %s %s. Estimates are not medical advice.
                """.formatted(name, servingSize, servingUnit);
        Map<String, Object> body = Map.of(
                "model", nutritionModel,
                "temperature", 0.1,
                "max_tokens", 1000,
                "chat_template_kwargs", Map.of("enable_thinking", false),
                "messages", List.of(Map.of("role", "user", "content", prompt)));
        String responseBody = client.post()
                .uri("/chat/completions")
                .header("Authorization", "Bearer " + apiKey)
                .contentType(MediaType.APPLICATION_JSON)
                .body(body)
                .retrieve()
                .body(String.class);
        JsonNode response = mapper.readTree(responseBody);
        String content = response.path("choices").path(0).path("message").path("content").asText();
        String json = content.replaceFirst("(?s)^\\s*```(?:json)?\\s*", "")
                .replaceFirst("(?s)\\s*```\\s*$", "").trim();
        return mapper.readValue(json, AiFoodAnalysisResponse.class);
    }
}
