package com.nhamhealth.nhamhealth_api.service.ai;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.nhamhealth.nhamhealth_api.dto.ai.FoodVisionComponent;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

class GeminiFoodNutritionEstimationServiceTests {
    private static final String VALID_ESTIMATE_JSON = """
            {"components":[{"index":0,"calories":165,"protein":31,
            "carbohydrates":0,"fat":3.6,"sugar":0,"fiber":0,"sodium":74,
            "confidence":0.90}]}
            """.replaceAll("\\s+", " ");

    @Test
    void returnsEmptyResultWhenComponentsListIsEmpty() {
        GeminiFoodNutritionEstimationService service = new GeminiFoodNutritionEstimationService(
                "https://generativelanguage.googleapis.com",
                "test-key",
                "gemini-3.8-flash",
                "gemini-3.7-flash",
                4096,
                null);

        FoodNutritionEstimationResult result = service.estimate(List.of());

        assertFalse(result.used());
        assertEquals(0, result.components().size());
    }

    @Test
    void parsesGeminiNutritionEstimateCorrectly() throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        List<String> responses = List.of(geminiResponse(mapper, VALID_ESTIMATE_JSON));
        AtomicInteger requests = new AtomicInteger();
        HttpServer server = server(responses, requests);

        try {
            GeminiFoodNutritionEstimationService service = new GeminiFoodNutritionEstimationService(
                    "http://localhost:" + server.getAddress().getPort(),
                    "test-key",
                    "gemini-3.8-flash",
                    "gemini-3.7-flash",
                    4096,
                    mapper,
                    null);

            FoodVisionComponent component = new FoodVisionComponent(
                    "Grilled Chicken", 100, "g", 0.9, 0.9, "grilled", "visible grilled mark");
            FoodNutritionEstimationResult result = service.estimate(List.of(component));

            assertTrue(result.used());
            assertEquals(1, requests.get());
            assertEquals(1, result.components().size());
            assertEquals(165, result.components().get(0).calories());
            assertEquals(31, result.components().get(0).protein());
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
                        "promptTokenCount", 80,
                        "candidatesTokenCount", 40));
        return mapper.writeValueAsString(body);
    }

    private static HttpServer server(List<String> responses, AtomicInteger counter) throws IOException {
        HttpServer server = HttpServer.create(new InetSocketAddress(0), 0);
        server.createContext("/", exchange -> {
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
}
