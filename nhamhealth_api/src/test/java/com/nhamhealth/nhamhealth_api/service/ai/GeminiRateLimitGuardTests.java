package com.nhamhealth.nhamhealth_api.service.ai;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.Duration;
import java.util.concurrent.atomic.AtomicLong;

import org.junit.jupiter.api.Test;

class GeminiRateLimitGuardTests {

    @Test
    void proactivelyLimitsRequestsWithinRollingWindow() {
        AtomicLong now = new AtomicLong();
        GeminiRateLimitGuard guard = new GeminiRateLimitGuard(
                Duration.ofMinutes(10), Duration.ofMinutes(1), 2, now::get);

        assertTrue(guard.tryAcquire());
        assertTrue(guard.tryAcquire());
        assertFalse(guard.tryAcquire());
        assertFalse(guard.isCallAllowed());

        now.set(Duration.ofSeconds(61).toNanos());
        assertTrue(guard.isCallAllowed());
        assertTrue(guard.tryAcquire());
    }

    @Test
    void providerCooldownBlocksNewReservations() {
        AtomicLong now = new AtomicLong();
        GeminiRateLimitGuard guard = new GeminiRateLimitGuard(
                Duration.ofMinutes(2), Duration.ofMinutes(1), 10, now::get);

        guard.recordRateLimit();
        assertFalse(guard.tryAcquire());

        now.set(Duration.ofMinutes(2).plusSeconds(1).toNanos());
        assertTrue(guard.tryAcquire());
    }
}
