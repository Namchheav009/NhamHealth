package com.nhamhealth.nhamhealth_api.service.ai;

import java.time.Duration;
import java.util.concurrent.atomic.AtomicLong;
import java.util.function.LongSupplier;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Shares Gemini rate-limit state across vision and nutrition calls.
 *
 * <p>A quota response from one stage is useful information for the next stage. Keeping that
 * information here prevents a food analysis from repeatedly calling a provider that has already
 * said it is unavailable, while still allowing Gemini to be tried again after a short cooldown.</p>
 */
@Component
public class GeminiRateLimitGuard {
    private final long cooldownNanos;
    private final LongSupplier nanoTime;
    private final AtomicLong blockedUntilNanos = new AtomicLong();

    @Autowired
    public GeminiRateLimitGuard(
            @Value("${app.ai.gemini.rate-limit-cooldown:PT10M}") Duration cooldown) {
        this(cooldown, System::nanoTime);
    }

    GeminiRateLimitGuard(Duration cooldown, LongSupplier nanoTime) {
        Duration safeCooldown = cooldown == null || cooldown.isNegative() || cooldown.isZero()
                ? Duration.ofMinutes(10) : cooldown;
        this.cooldownNanos = safeCooldown.toNanos();
        this.nanoTime = nanoTime;
    }

    public boolean isCallAllowed() {
        return remainingSeconds() == 0;
    }

    public long remainingSeconds() {
        long remaining = blockedUntilNanos.get() - nanoTime.getAsLong();
        if (remaining <= 0) return 0;
        return Math.max(1, (remaining + 999_999_999L) / 1_000_000_000L);
    }

    public void recordRateLimit() {
        long blockedUntil = nanoTime.getAsLong() + cooldownNanos;
        blockedUntilNanos.accumulateAndGet(blockedUntil, Math::max);
    }

}
