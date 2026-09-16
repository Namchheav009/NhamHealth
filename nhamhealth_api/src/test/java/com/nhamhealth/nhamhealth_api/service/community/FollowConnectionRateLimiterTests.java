package com.nhamhealth.nhamhealth_api.service.community;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;

import org.junit.jupiter.api.Test;

class FollowConnectionRateLimiterTests {
    @Test
    void returnsRetryAfterWhenConfiguredLimitIsExceeded() {
        FollowConnectionRateLimiter limiter = new FollowConnectionRateLimiter(
                2, Duration.ofSeconds(30),
                Clock.fixed(Instant.parse("2026-09-16T08:00:00Z"), ZoneOffset.UTC));

        assertDoesNotThrow(() -> limiter.check(7));
        assertDoesNotThrow(() -> limiter.check(7));
        FollowConnectionRateLimitException error = assertThrows(
                FollowConnectionRateLimitException.class, () -> limiter.check(7));

        assertEquals(30, error.getRetryAfterSeconds());
    }
}
