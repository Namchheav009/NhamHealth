package com.nhamhealth.nhamhealth_api.service;

import java.util.Base64;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.server.ResponseStatusException;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.nhamhealth.nhamhealth_api.dto.response.AiFoodAnalysisResponse;

import static org.springframework.http.HttpStatus.BAD_GATEWAY;
import static org.springframework.http.HttpStatus.SERVICE_UNAVAILABLE;

@Service
public class NvidiaFoodVisionService {
    private static final String PROMPT = """
            Analyze the food visible in this image. Identify the most likely dish and estimate
            nutrition for the visible portion. Return JSON only with exactly these fields:
            name (string), confidence (0 to 1), calories, protein, carbs, fat, sugar (numbers),
            servingSize (number), servingUnit (string), recommendationTitle (string), and
            recommendation (one short practical sentence). If no food is visible, use name
            \"Unknown food\", confidence 0, and zero nutrition. Estimates are not medical advice.
            For visible food, calories, protein, carbs, fat, servingSize, recommendationTitle,
            and recommendation must not be missing. Example shape:
            {\"name\":\"Hamburger\",\"confidence\":0.8,\"calories\":350,\"protein\":20,
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
                                Map.of("type", "text", "text", PROMPT),
                                Map.of("type", "image_url", "image_url", Map.of("url", dataUrl))))));
        try {
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
            AiFoodAnalysisResponse result = mapper.readValue(json, AiFoodAnalysisResponse.class);
            if (!"Unknown food".equalsIgnoreCase(result.name()) && result.calories() <= 0) {
                result = estimateNutrition(result.name(), result.servingSize(), result.servingUnit());
            }
            if (!"Unknown food".equalsIgnoreCase(result.name())
                    && (result.calories() <= 0 || result.servingSize() <= 0
                    || result.recommendation() == null || result.recommendation().isBlank())) {
                throw new IllegalStateException("NVIDIA returned incomplete nutrition data.");
            }
            return result;
        } catch (ResponseStatusException error) {
            throw error;
        } catch (Exception error) {
            throw new ResponseStatusException(BAD_GATEWAY,
                    "The NVIDIA food vision service could not analyze this image.", error);
        }
    }

    private AiFoodAnalysisResponse estimateNutrition(String name, double servingSize, String servingUnit)
            throws Exception {
        String prompt = """
                Estimate realistic nutrition for the described food portion. Return JSON only with
                exactly these keys: name, confidence, calories, protein, carbs, fat, sugar,
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
