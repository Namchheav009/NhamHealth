package com.nhamhealth.nhamhealth_api.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.Test;

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

    private static FoodVisionComponent component() {
        return new FoodVisionComponent(
                "Chocolate Frappuccino", 350, "ml", 0.95, 0.82,
                "blended", "a chocolate blended coffee drink fills the cup");
    }

    private static NvidiaFoodNutritionEstimationService service(HttpServer server) {
        return new NvidiaFoodNutritionEstimationService(
                "http://127.0.0.1:" + server.getAddress().getPort(),
                "test-key", "nutrition-model", 1_200, "low", new ObjectMapper());
    }

    private static HttpServer server(String response) throws IOException {
        HttpServer server = HttpServer.create(new InetSocketAddress(0), 0);
        server.createContext("/chat/completions", exchange -> respond(exchange, response));
        server.start();
        return server;
    }

    private static String completion(String content) throws Exception {
        return new ObjectMapper().writeValueAsString(Map.of(
                "choices", List.of(Map.of("message", Map.of("content", content))),
                "usage", Map.of("prompt_tokens", 12, "completion_tokens", 18)));
    }

    private static void respond(HttpExchange exchange, String body) throws IOException {
        exchange.getRequestBody().readAllBytes();
        byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", "application/json");
        exchange.sendResponseHeaders(200, bytes.length);
        exchange.getResponseBody().write(bytes);
        exchange.close();
    }
}
