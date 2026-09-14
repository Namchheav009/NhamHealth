package com.nhamhealth.nhamhealth_api.service.ai;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertThrows;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.nhamhealth.nhamhealth_api.dto.ai.FoodVisionResult;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

class GeminiFoodVisionServiceTests {
    private static final String VALID_VISION_JSON = """
            {"foodDetected":true,"reason":"","mealName":"Egg fried rice",
            "cuisine":"Unknown","type":"food","mealConfidence":0.82,
            "portionConfidence":0.76,"preparationConfidence":0.81,
            "components":[{"name":"Egg fried rice","estimatedAmount":1,"unit":"bowl",
            "confidence":0.82,"portionConfidence":0.76,"preparationMethod":"fried",
            "visibleEvidence":"fried rice and egg fill one bowl"}],
            "candidates":[{"name":"Egg fried rice","confidence":0.82},
            {"name":"Chicken fried rice","confidence":0.12}]}
            """.replaceAll("\\s+", " ");

    @Test
    void parsesGeminiVisionResponseCorrectly() throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        List<String> responses = List.of(geminiResponse(mapper, VALID_VISION_JSON));
        AtomicInteger requests = new AtomicInteger();
        AtomicReference<String> requestBody = new AtomicReference<>();
        HttpServer server = server(responses, requests, requestBody);

        try {
            GeminiFoodVisionService service = new GeminiFoodVisionService(
                    "http://localhost:" + server.getAddress().getPort(),
                    "test-key",
                    "gemini-3.8-flash",
                    "gemini-3.7-flash",
                    "prompt-v1",
                    4096,
                    mapper,
                    new FoodVisionResultValidator(),
                    null);

            AiFoodModelResult result = service.analyze(jpeg(), "image/jpeg");
            AiFoodModelResult repeated = service.analyze(jpeg(), "image/jpeg");

            assertEquals(1, requests.get());
            assertSame(result, repeated);
            assertEquals("Egg fried rice", result.response().mealName());
            assertEquals(1, result.response().components().size());
            assertEquals("gemini-3.8-flash", result.modelName());
            assertFalse(result.nutritionFallbackUsed());
            assertTrue(requestBody.get().contains("\"responseMimeType\":\"application/json\""));
            assertTrue(requestBody.get().contains("\"responseJsonSchema\""));
            assertTrue(requestBody.get().contains("\"thinkingLevel\":\"low\""));
            assertFalse(requestBody.get().contains("\"temperature\""));
        } finally {
            server.stop(0);
        }
    }

    @Test
    void repairsInvalidStructuredOutputOnTheSamePrimaryModel() throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        List<String> responses = List.of(
                geminiResponse(mapper, "{\"foodDetected\":true"),
                geminiResponse(mapper, VALID_VISION_JSON));
        AtomicInteger requests = new AtomicInteger();
        HttpServer server = server(responses, requests);

        try {
            GeminiFoodVisionService service = new GeminiFoodVisionService(
                    "http://localhost:" + server.getAddress().getPort(),
                    "test-key",
                    "gemini-3.8-flash",
                    "gemini-3.7-flash",
                    "prompt-v1",
                    4096,
                    mapper,
                    new FoodVisionResultValidator(),
                    null);

            AiFoodModelResult result = service.analyze(jpeg(), "image/jpeg");

            assertEquals(2, requests.get());
            assertEquals("gemini-3.8-flash", result.modelName());
            assertEquals("Egg fried rice", result.response().mealName());
        } finally {
            server.stop(0);
        }
    }

    @Test
    void throwsServiceUnavailableWhenApiKeyIsMissing() {
        GeminiFoodVisionService service = new GeminiFoodVisionService(
                "https://generativelanguage.googleapis.com",
                "",
                "gemini-3.8-flash",
                "gemini-3.7-flash",
                "prompt-v1",
                4096,
                null);

        ResponseStatusException error = assertThrows(
                ResponseStatusException.class, () -> service.analyze(jpeg(), "image/jpeg"));

        assertEquals(503, error.getStatusCode().value());
    }

    @Test
    void fallsBackToNvidiaWhenGeminiCredentialsRejected() throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress(0), 0);
        server.createContext("/", exchange -> {
            try {
                send(exchange, 401, "{\"error\":{\"code\":401,\"message\":\"Request had invalid authentication credentials.\"}}");
            } catch (IOException ignored) {
            }
        });
        server.start();

        try {
            NvidiaFoodVisionService mockNvidia = org.mockito.Mockito.mock(NvidiaFoodVisionService.class);
            org.mockito.Mockito.when(mockNvidia.isConfigured()).thenReturn(true);
            ObjectMapper mapper = new ObjectMapper();
            FoodVisionResult normalized = new FoodVisionResultValidator().validateAndNormalize(
                    mapper.readValue(VALID_VISION_JSON, FoodVisionResult.class));
            org.mockito.Mockito.when(mockNvidia.analyze(org.mockito.ArgumentMatchers.any(), org.mockito.ArgumentMatchers.any()))
                    .thenReturn(new AiFoodModelResult(normalized, "meta/llama-3.2-11b-vision-instruct", "test", false, 10, 10, 50));

            GeminiFoodVisionService service = new GeminiFoodVisionService(
                    "http://localhost:" + server.getAddress().getPort(),
                    "invalid-key",
                    "gemini-3.8-flash",
                    "gemini-3.7-flash",
                    "prompt-v1",
                    4096,
                    mapper,
                    new FoodVisionResultValidator(),
                    mockNvidia);

            AiFoodModelResult result = service.analyze(jpeg(), "image/jpeg");
            assertEquals("Egg fried rice", result.response().mealName());
            assertEquals("meta/llama-3.2-11b-vision-instruct", result.modelName());
        } finally {
            server.stop(0);
        }
    }

    private static String geminiResponse(ObjectMapper mapper, String text) throws Exception {
        Map<String, Object> body = Map.of(
                "candidates", List.of(
                        Map.of("content", Map.of(
                                "parts", List.of(Map.of("text", text))))),
                "usageMetadata", Map.of(
                        "promptTokenCount", 120,
                        "candidatesTokenCount", 45));
        return mapper.writeValueAsString(body);
    }

    private static HttpServer server(List<String> responses, AtomicInteger counter) throws IOException {
        return server(responses, counter, new AtomicReference<>());
    }

    private static HttpServer server(
            List<String> responses, AtomicInteger counter,
            AtomicReference<String> requestBody) throws IOException {
        HttpServer server = HttpServer.create(new InetSocketAddress(0), 0);
        server.createContext("/", exchange -> {
            requestBody.set(new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8));
            int requestIndex = counter.getAndIncrement();
            if (requestIndex >= responses.size()) {
                send(exchange, 500, "{\"error\":\"Unexpected request\"}");
                return;
            }
            send(exchange, 200, responses.get(requestIndex));
        });
        server.start();
        return server;
    }

    private static void send(HttpExchange exchange, int status, String body) throws IOException {
        byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", "application/json");
        exchange.sendResponseHeaders(status, bytes.length);
        exchange.getResponseBody().write(bytes);
        exchange.close();
    }

    private static byte[] jpeg() {
        return new byte[] {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF, (byte) 0xE0, 0x00};
    }
}
