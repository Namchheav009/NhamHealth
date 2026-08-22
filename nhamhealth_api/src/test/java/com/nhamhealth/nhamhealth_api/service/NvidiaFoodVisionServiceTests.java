package com.nhamhealth.nhamhealth_api.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
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
    void retriesVisionOnceWhenTheProviderReturnsTruncatedJson() throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        List<String> responses = List.of(
                completion(mapper, "{\"mealName\":\"Egg fried", "length"),
                completion(mapper, VALID_VISION_JSON, "stop"));
        AtomicInteger requests = new AtomicInteger();
        HttpServer server = server(responses, requests);

        try {
            NvidiaFoodVisionService service = service(server);
            AiFoodModelResult result = service.analyze(jpeg(), "image/jpeg");

            assertEquals(2, requests.get());
            assertEquals("Egg fried rice", result.response().mealName());
            assertEquals(1, result.response().components().size());
            assertTrue(result.modelName().contains("fallback-vision-model"));
            assertFalse(result.nutritionFallbackUsed());
        } finally {
            server.stop(0);
        }
    }

    @Test
    void recoversLowConfidenceFoodNameWhenFallbackJsonIsMalformed() throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        List<String> responses = List.of(
                completion(mapper, "{\"mealName\":\"Milk", "length"),
                completion(mapper, "{\"mealName\":\"Milk Tea\" broken response}", "stop"));
        AtomicInteger requests = new AtomicInteger();
        HttpServer server = server(responses, requests);

        try {
            AiFoodModelResult result = service(server).analyze(jpeg(), "image/jpeg");

            assertEquals(2, requests.get());
            assertEquals("Milk Tea", result.response().mealName());
            assertEquals(0.25, result.response().mealConfidence());
            assertEquals("serving", result.response().components().getFirst().unit());
        } finally {
            server.stop(0);
        }
    }

    @Test
    void retriesWhenStructuredJsonContainsAnInvalidPortion() throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        String invalid = VALID_VISION_JSON.replace("\"estimatedAmount\":1", "\"estimatedAmount\":0");
        List<String> responses = List.of(
                completion(mapper, invalid, "stop"),
                completion(mapper, VALID_VISION_JSON, "stop"));
        AtomicInteger requests = new AtomicInteger();
        HttpServer server = server(responses, requests);

        try {
            AiFoodModelResult result = service(server).analyze(jpeg(), "image/jpeg");

            assertEquals(2, requests.get());
            assertEquals(1, result.response().components().getFirst().estimatedAmount());
        } finally {
            server.stop(0);
        }
    }

    @Test
    void returnsExplicitNonFoodResultWithoutInventingComponents() throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        String nonFood = """
                {"foodDetected":false,"reason":"No food or drink was clearly visible.",
                "mealName":"Unknown food","cuisine":"Unknown","type":"food",
                "mealConfidence":0,"portionConfidence":0,"preparationConfidence":0,
                "components":[],"candidates":[]}
                """.replaceAll("\\s+", " ");
        AtomicInteger requests = new AtomicInteger();
        HttpServer server = server(List.of(completion(mapper, nonFood, "stop")), requests);

        try {
            AiFoodModelResult result = service(server).analyze(jpeg(), "image/jpeg");

            assertFalse(result.response().foodDetected());
            assertTrue(result.response().components().isEmpty());
            assertEquals(1, requests.get());
        } finally {
            server.stop(0);
        }
    }

    private static NvidiaFoodVisionService service(HttpServer server) {
        return new NvidiaFoodVisionService(
                "http://127.0.0.1:" + server.getAddress().getPort(),
                "test-key", "vision-model", "fallback-vision-model", "unused-nutrition-model",
                "test-prompt", 4096, "low");
    }

    private static HttpServer server(List<String> responses, AtomicInteger requests)
            throws IOException {
        HttpServer server = HttpServer.create(new InetSocketAddress(0), 0);
        server.createContext("/chat/completions", exchange -> respond(
                exchange, responses.get(Math.min(requests.getAndIncrement(), responses.size() - 1))));
        server.start();
        return server;
    }

    private static byte[] jpeg() {
        return new byte[] {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF};
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
