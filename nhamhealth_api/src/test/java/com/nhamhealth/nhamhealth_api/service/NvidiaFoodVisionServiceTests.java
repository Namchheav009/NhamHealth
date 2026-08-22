package com.nhamhealth.nhamhealth_api.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

import org.junit.jupiter.api.Test;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

class NvidiaFoodVisionServiceTests {
    private static final String VALID_FOOD_JSON = """
            {"name":"Egg fried rice","analysis":"Fried rice with egg in one bowl.",
            "confidence":0.82,"calories":495,"protein":20,"carbs":70,"fat":15,
            "sugar":5,"servingSize":1,"servingUnit":"bowl",
            "recommendationTitle":"Add vegetables","recommendation":"Add a vegetable side."}
            """.replaceAll("\\s+", " ");

    @Test
    void retriesVisionOnceWhenTheProviderReturnsTruncatedJson() throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        List<String> responses = List.of(
                completion(mapper, "{\"name\":\"Egg fried", "length"),
                completion(mapper, VALID_FOOD_JSON, "stop"),
                completion(mapper, VALID_FOOD_JSON, "stop"));
        AtomicInteger requests = new AtomicInteger();
        HttpServer server = HttpServer.create(new InetSocketAddress(0), 0);
        server.createContext("/chat/completions", exchange -> respond(
                exchange, responses.get(Math.min(requests.getAndIncrement(), responses.size() - 1))));
        server.start();

        try {
            NvidiaFoodVisionService service = new NvidiaFoodVisionService(
                    "http://127.0.0.1:" + server.getAddress().getPort(),
                    "test-key", "vision-model", "fallback-vision-model", "nutrition-model",
                    "test-prompt", 4096, "low");

            AiFoodModelResult result = service.analyze(
                    new byte[] {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF}, "image/jpeg");

            assertEquals(3, requests.get());
            assertEquals("Egg fried rice", result.response().name());
            assertTrue(result.modelName().contains("fallback-vision-model"));
            assertTrue(result.modelName().contains("nutrition-model"));
        } finally {
            server.stop(0);
        }
    }

    @Test
    void recoversFoodNameWhenFallbackJsonIsMalformed() throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        String malformedIdentity = "{\"name\":\"Milk Tea\" broken response}";
        List<String> responses = List.of(
                completion(mapper, "{\"name\":\"Milk", "length"),
                completion(mapper, malformedIdentity, "stop"));
        AtomicInteger requests = new AtomicInteger();
        HttpServer server = HttpServer.create(new InetSocketAddress(0), 0);
        server.createContext("/chat/completions", exchange -> respond(
                exchange, responses.get(Math.min(requests.getAndIncrement(), responses.size() - 1))));
        server.start();

        try {
            NvidiaFoodVisionService service = new NvidiaFoodVisionService(
                    "http://127.0.0.1:" + server.getAddress().getPort(),
                    "test-key", "vision-model", "fallback-vision-model", "nutrition-model",
                    "test-prompt", 4096, "low");

            AiFoodModelResult result = service.analyze(
                    new byte[] {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF}, "image/jpeg");

            assertEquals(2, requests.get());
            assertEquals("Milk Tea", result.response().name());
            assertEquals("IDENTITY_ONLY", result.response().dataSource());
        } finally {
            server.stop(0);
        }
    }

    @Test
    void normalizesInvalidModelNutritionInsteadOfReturningBadGateway() throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        String inconsistent = VALID_FOOD_JSON.replace("\"calories\":495", "\"calories\":50");
        List<String> responses = List.of(
                completion(mapper, inconsistent, "stop"),
                completion(mapper, inconsistent, "stop"));
        AtomicInteger requests = new AtomicInteger();
        HttpServer server = HttpServer.create(new InetSocketAddress(0), 0);
        server.createContext("/chat/completions", exchange -> respond(
                exchange, responses.get(Math.min(requests.getAndIncrement(), responses.size() - 1))));
        server.start();

        try {
            NvidiaFoodVisionService service = new NvidiaFoodVisionService(
                    "http://127.0.0.1:" + server.getAddress().getPort(),
                    "test-key", "vision-model", "fallback-vision-model", "nutrition-model",
                    "test-prompt", 4096, "low");

            AiFoodModelResult result = service.analyze(
                    new byte[] {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF}, "image/jpeg");

            assertEquals(2, requests.get());
            assertEquals("Egg fried rice", result.response().name());
            assertEquals(495, result.response().calories());
            assertEquals(0.59, result.response().confidence());
            assertTrue(NutritionEstimateValidator.isPlausible(result.response()));
        } finally {
            server.stop(0);
        }
    }

    @Test
    void returnsUnknownFoodWhenNeitherEstimateHasNutritionEvidence() throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        String noMacros = VALID_FOOD_JSON
                .replace("\"protein\":20", "\"protein\":0")
                .replace("\"carbs\":70", "\"carbs\":0")
                .replace("\"fat\":15", "\"fat\":0");
        List<String> responses = List.of(
                completion(mapper, noMacros, "stop"),
                completion(mapper, noMacros, "stop"));
        AtomicInteger requests = new AtomicInteger();
        HttpServer server = HttpServer.create(new InetSocketAddress(0), 0);
        server.createContext("/chat/completions", exchange -> respond(
                exchange, responses.get(Math.min(requests.getAndIncrement(), responses.size() - 1))));
        server.start();

        try {
            NvidiaFoodVisionService service = new NvidiaFoodVisionService(
                    "http://127.0.0.1:" + server.getAddress().getPort(),
                    "test-key", "vision-model", "fallback-vision-model", "nutrition-model",
                    "test-prompt", 4096, "low");

            AiFoodModelResult result = service.analyze(
                    new byte[] {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF}, "image/jpeg");

            assertEquals(2, requests.get());
            assertEquals("Unknown food", result.response().name());
            assertEquals(0, result.response().calories());
            assertEquals("Try another photo", result.response().recommendationTitle());
        } finally {
            server.stop(0);
        }
    }

    private static String completion(ObjectMapper mapper, String content, String finishReason)
            throws Exception {
        return mapper.writeValueAsString(Map.of(
                "choices", List.of(Map.of(
                        "message", Map.of("content", content),
                        "finish_reason", finishReason)),
                "usage", Map.of("prompt_tokens", 10, "completion_tokens", 20)));
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
