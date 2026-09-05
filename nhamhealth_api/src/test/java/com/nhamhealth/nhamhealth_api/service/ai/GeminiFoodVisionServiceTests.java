package com.nhamhealth.nhamhealth_api.service.ai;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;

import com.fasterxml.jackson.databind.ObjectMapper;
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

            assertEquals(1, requests.get());
            assertEquals("Egg fried rice", result.response().mealName());
            assertEquals(1, result.response().components().size());
            assertEquals("gemini-3.8-flash", result.modelName());
            assertFalse(result.nutritionFallbackUsed());
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

    private static byte[] jpeg() {
        return new byte[] {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF, (byte) 0xE0, 0x00};
    }
}
