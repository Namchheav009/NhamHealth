package com.nhamhealth.nhamhealth_api.service.ai;

import java.time.Duration;
import java.util.ArrayDeque;
import java.util.Deque;
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
    private final long windowNanos;
    private final int maximumRequests;
    private final LongSupplier nanoTime;
    private final AtomicLong blockedUntilNanos = new AtomicLong();
    private final Deque<Long> requestTimes = new ArrayDeque<>();

    @Autowired
    public GeminiRateLimitGuard(
            @Value("${app.ai.gemini.rate-limit-cooldown:PT1M}") Duration cooldown,
            @Value("${app.ai.gemini.maximum-requests-per-minute:12}") int maximumRequests) {
        this(cooldown, Duration.ofMinutes(1), maximumRequests, System::nanoTime);
    }

    GeminiRateLimitGuard(Duration cooldown, LongSupplier nanoTime) {
        this(cooldown, Duration.ofMinutes(1), Integer.MAX_VALUE, nanoTime);
    }

    GeminiRateLimitGuard(
            Duration cooldown, Duration window, int maximumRequests, LongSupplier nanoTime) {
        Duration safeCooldown = cooldown == null || cooldown.isNegative() || cooldown.isZero()
                ? Duration.ofMinutes(1) : cooldown;
        Duration safeWindow = window == null || window.isNegative() || window.isZero()
                ? Duration.ofMinutes(1) : window;
        this.cooldownNanos = safeCooldown.toNanos();
        this.windowNanos = safeWindow.toNanos();
        this.maximumRequests = Math.max(1, maximumRequests);
        this.nanoTime = nanoTime;
    }

    public synchronized boolean isCallAllowed() {
        long now = nanoTime.getAsLong();
        evictExpiredRequests(now);
        return blockedUntilNanos.get() <= now && requestTimes.size() < maximumRequests;
    }

    /** Reserves capacity immediately before one outbound Gemini request. */
    public synchronized boolean tryAcquire() {
        long now = nanoTime.getAsLong();
        evictExpiredRequests(now);
        if (blockedUntilNanos.get() > now || requestTimes.size() >= maximumRequests) return false;
        requestTimes.addLast(now);
        return true;
    }

    public synchronized long remainingSeconds() {
        long now = nanoTime.getAsLong();
        evictExpiredRequests(now);
        long remaining = blockedUntilNanos.get() - now;
        if (requestTimes.size() >= maximumRequests && !requestTimes.isEmpty()) {
            remaining = Math.max(remaining, requestTimes.peekFirst() + windowNanos - now);
        }
        if (remaining <= 0) return 0;
        return Math.max(1, (remaining + 999_999_999L) / 1_000_000_000L);
    }

    public void recordRateLimit() {
        long blockedUntil = nanoTime.getAsLong() + cooldownNanos;
        blockedUntilNanos.accumulateAndGet(blockedUntil, Math::max);
    }

    private void evictExpiredRequests(long now) {
        long cutoff = now - windowNanos;
        while (!requestTimes.isEmpty() && requestTimes.peekFirst() <= cutoff) {
            requestTimes.removeFirst();
        }
    }

}
