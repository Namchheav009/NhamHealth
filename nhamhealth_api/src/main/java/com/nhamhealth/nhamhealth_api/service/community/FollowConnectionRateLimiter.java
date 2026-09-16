package com.nhamhealth.nhamhealth_api.service.community;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class FollowConnectionRateLimiter {
    private final int maximumRequests;
    private final Duration window;
    private final Clock clock;
    private final Map<Integer, Deque<Instant>> attempts = new ConcurrentHashMap<>();

    @Autowired
    public FollowConnectionRateLimiter(
            @Value("${app.follow-connections.rate-limit.max-requests:20}") int maximumRequests,
            @Value("${app.follow-connections.rate-limit.window:PT1M}") Duration window) {
        this(maximumRequests, window, Clock.systemUTC());
    }

    FollowConnectionRateLimiter(int maximumRequests, Duration window, Clock clock) {
        if (maximumRequests < 1 || window.isZero() || window.isNegative()) {
            throw new IllegalArgumentException("Friend-request rate limit configuration is invalid");
        }
        this.maximumRequests = maximumRequests;
        this.window = window;
        this.clock = clock;
    }

    public void check(Integer senderId) {
        Instant now = clock.instant();
        Deque<Instant> userAttempts = attempts.computeIfAbsent(senderId, ignored -> new ArrayDeque<>());
        synchronized (userAttempts) {
            Instant cutoff = now.minus(window);
            while (!userAttempts.isEmpty() && !userAttempts.peekFirst().isAfter(cutoff)) {
                userAttempts.removeFirst();
            }
            if (userAttempts.size() >= maximumRequests) {
                Duration remaining = Duration.between(now, userAttempts.peekFirst().plus(window));
                throw new FollowConnectionRateLimitException((remaining.toMillis() + 999) / 1000);
            }
            userAttempts.addLast(now);
        }
    }
}
