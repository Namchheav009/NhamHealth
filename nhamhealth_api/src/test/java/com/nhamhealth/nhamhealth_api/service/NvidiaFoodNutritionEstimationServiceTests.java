package com.nhamhealth.nhamhealth_api.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

import org.junit.jupiter.api.Test;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.nhamhealth.nhamhealth_api.dto.ai.FoodVisionComponent;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

class NvidiaFoodNutritionEstimationServiceTests {

    @Test
    void parsesPlausibleWholePortionNutrition() throws Exception {
        String estimate = """
                {"components":[{"index":0,"calories":420,"protein":6,
                "carbohydrates":68,"fat":14,"sugar":55,"fiber":2,
                "sodium":260,"confidence":0.68}]}
                """.replaceAll("\\s+", " ");
        HttpServer server = server(completion(estimate));
        try {
            var result = service(server).estimate(List.of(component()));

            assertEquals(1, result.components().size());
            assertEquals(420, result.components().getFirst().calories());
            assertEquals(68, result.components().getFirst().carbohydrates());
            assertEquals("nutrition-model", result.modelName());
            assertEquals(12, result.promptTokens());
            assertEquals(18, result.completionTokens());
        } finally {
            server.stop(0);
        }
    }

    @Test
    void rejectsNutritionWhereSugarExceedsCarbohydrates() throws Exception {
        String estimate = """
                {"components":[{"index":0,"calories":300,"protein":3,
                "carbohydrates":20,"fat":10,"sugar":40,"fiber":1,
                "sodium":100,"confidence":0.60}]}
                """.replaceAll("\\s+", " ");
        HttpServer server = server(completion(estimate));
        try {
            assertThrows(IllegalArgumentException.class,
                    () -> service(server).estimate(List.of(component())));
        } finally {
            server.stop(0);
        }
    }

    @Test
    void retriesInvalidStructuredNutritionAndSeparatesInstructionsFromData() throws Exception {
        String invalid = "{\"components\":[{\"index\":0,\"calories\":300}]";
        String valid = """
                {"components":[{"index":0,"calories":420,"protein":6,
                "carbohydrates":68,"fat":14,"sugar":55,"fiber":2,
                "sodium":260,"confidence":0.68}]}
                """.replaceAll("\\s+", " ");
        AtomicInteger requests = new AtomicInteger();
        List<String> requestBodies = new ArrayList<>();
        HttpServer server = server(
                List.of(completion(invalid), completion(valid)), requests, requestBodies);

        try {
            var result = service(server).estimate(List.of(component()));

            assertEquals(2, requests.get());
            assertEquals(24, result.promptTokens());
            assertEquals(36, result.completionTokens());
            JsonNode retryRequest = new ObjectMapper().readTree(requestBodies.get(1));
            assertEquals("system", retryRequest.path("messages").path(0).path("role").asText());
            assertTrue(retryRequest.path("messages").path(0).path("content").asText()
                    .contains("untrusted data"));
            assertTrue(retryRequest.path("messages").path(0).path("content").asText()
                    .contains("do not add container capacity"));
            assertTrue(retryRequest.path("messages").path(0).path("content").asText()
                    .contains("distinguish cooked portions from raw ingredient weights"));
            assertTrue(retryRequest.path("messages").path(1).path("content").asText()
                    .contains("previous response was invalid"));
        } finally {
            server.stop(0);
        }
    }

    private static FoodVisionComponent component() {
        return new FoodVisionComponent(
                "Chocolate Frappuccino", 350, "ml", 0.95, 0.82,
                "blended", "a chocolate blended coffee drink fills the cup");
    }

    private static NvidiaFoodNutritionEstimationService service(HttpServer server) {
        return new NvidiaFoodNutritionEstimationService(
                "http://127.0.0.1:" + server.getAddress().getPort(),
                "test-key", "nutrition-model", 1_200, new ObjectMapper());
    }

    private static HttpServer server(String response) throws IOException {
        return server(List.of(response), new AtomicInteger(), null);
    }

    private static HttpServer server(
            List<String> responses, AtomicInteger requests, List<String> requestBodies)
            throws IOException {
        HttpServer server = HttpServer.create(new InetSocketAddress(0), 0);
        server.createContext("/chat/completions", exchange -> {
            int index = Math.min(requests.getAndIncrement(), responses.size() - 1);
            respond(exchange, responses.get(index), requestBodies);
        });
        server.start();
        return server;
    }

    private static String completion(String content) throws Exception {
        return new ObjectMapper().writeValueAsString(Map.of(
                "choices", List.of(Map.of("message", Map.of("content", content))),
                "usage", Map.of("prompt_tokens", 12, "completion_tokens", 18)));
    }

    private static void respond(
            HttpExchange exchange, String body, List<String> requestBodies) throws IOException {
        byte[] request = exchange.getRequestBody().readAllBytes();
        if (requestBodies != null) {
            requestBodies.add(new String(request, StandardCharsets.UTF_8));
        }
        byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", "application/json");
        exchange.sendResponseHeaders(200, bytes.length);
        exchange.getResponseBody().write(bytes);
        exchange.close();
    }
}
