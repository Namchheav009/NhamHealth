package com.nhamhealth.nhamhealth_api.service.ai;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

import org.junit.jupiter.api.Test;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.nhamhealth.nhamhealth_api.dto.ai.FoodComponentNutritionEstimate;
import com.nhamhealth.nhamhealth_api.dto.ai.FoodVisionComponent;
import com.nhamhealth.nhamhealth_api.dto.ai.FoodVisionResult;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

class GeminiRateLimitFallbackTests {

    @Test
    void oneQuotaResponseMakesBothStagesUseFallbackDuringCooldown() throws Exception {
        AtomicInteger geminiRequests = new AtomicInteger();
        HttpServer server = rateLimitedServer(geminiRequests);

        try {
            GeminiRateLimitGuard guard = new GeminiRateLimitGuard(
                    Duration.ofMinutes(10), System::nanoTime);
            NvidiaFoodVisionService visionFallback = mock(NvidiaFoodVisionService.class);
            when(visionFallback.isConfigured()).thenReturn(true);
            AiFoodModelResult expectedVision = new AiFoodModelResult(
                    noFoodResult(), "nvidia-vision", "prompt-v1", false, 0, 0, 25);
            when(visionFallback.analyze(any(), any())).thenReturn(expectedVision);

            GeminiFoodVisionService visionService = new GeminiFoodVisionService(
                    "http://localhost:" + server.getAddress().getPort(),
                    "test-key",
                    "gemini-primary",
                    "gemini-secondary",
                    "prompt-v1",
                    4096,
                    new ObjectMapper(),
                    new FoodVisionResultValidator(),
                    visionFallback,
                    guard);

            assertSame(expectedVision, visionService.analyze(jpeg(), "image/jpeg"));
            assertEquals(1, geminiRequests.get(),
                    "A quota response must not be retried against more Gemini models");

            NvidiaFoodNutritionEstimationService nutritionFallback =
                    mock(NvidiaFoodNutritionEstimationService.class);
            FoodVisionComponent component = new FoodVisionComponent(
                    "Rice", 200, "g", 0.9, 0.8, "steamed", "visible rice");
            FoodNutritionEstimationResult expectedNutrition = new FoodNutritionEstimationResult(
                    List.of(new FoodComponentNutritionEstimate(
                            0, 260, 5, 56, 1, 0, 1, 2, 0.7)),
                    "nvidia-nutrition", 10, 10, 30);
            when(nutritionFallback.estimate(List.of(component))).thenReturn(expectedNutrition);

            GeminiFoodNutritionEstimationService nutritionService =
                    new GeminiFoodNutritionEstimationService(
                            "http://localhost:" + server.getAddress().getPort(),
                            "test-key",
                            "gemini-primary",
                            "gemini-secondary",
                            1200,
                            new ObjectMapper(),
                            nutritionFallback,
                            guard);

            assertSame(expectedNutrition, nutritionService.estimate(List.of(component)));
            assertEquals(1, geminiRequests.get(),
                    "Nutrition should reuse the rate-limit state learned by vision");
            verify(visionFallback).analyze(any(), any());
            verify(nutritionFallback, times(1)).estimate(List.of(component));
        } finally {
            server.stop(0);
        }
    }

    private static FoodVisionResult noFoodResult() {
        return new FoodVisionResult(
                false,
                "No food or drink was clearly visible.",
                "Unknown food",
                "Unknown",
                "food",
                0,
                0,
                0,
                List.of(),
                List.of());
    }

    private static HttpServer rateLimitedServer(AtomicInteger requests) throws IOException {
        HttpServer server = HttpServer.create(new InetSocketAddress(0), 0);
        server.createContext("/", exchange -> {
            requests.incrementAndGet();
            send(exchange, 429, "{\"error\":{\"code\":429,\"message\":\"Quota exceeded\"}}");
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
