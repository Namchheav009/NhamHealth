package com.nhamhealth.nhamhealth_api.service.auth;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Locale;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import com.nhamhealth.nhamhealth_api.exception.PasswordResetException;

/** Temporary, per-account login throttling. No account state is permanently changed. */
@Service
public class LoginAttemptService {
    private final ConcurrentHashMap<String, Attempts> attempts = new ConcurrentHashMap<>();
    private final int maximumFailures;
    private final Duration window;
    private final Duration lockDuration;
    private final Clock clock;

    public LoginAttemptService(
            @Value("${app.auth.login-rate-limit.maximum-failures:5}") int maximumFailures,
            @Value("${app.auth.login-rate-limit.window:PT10M}") Duration window,
            @Value("${app.auth.login-rate-limit.lock-duration:PT15M}") Duration lockDuration) {
        if (maximumFailures < 1 || window.isNegative() || window.isZero()
                || lockDuration.isNegative() || lockDuration.isZero()) {
            throw new IllegalArgumentException("Login rate-limit settings must be positive");
        }
        this.maximumFailures = maximumFailures;
        this.window = window;
        this.lockDuration = lockDuration;
        this.clock = Clock.systemUTC();
    }

    public void checkAllowed(String email) {
        String key = normalize(email);
        Attempts current = attempts.get(key);
        Instant now = clock.instant();
        if (current != null && current.lockedUntil() != null && now.isBefore(current.lockedUntil())) {
            throw throttled();
        }
        if (current != null && now.isAfter(current.windowStartedAt().plus(window))) {
            attempts.remove(key, current);
        }
    }

    public void recordFailure(String email) {
        String key = normalize(email);
        Instant now = clock.instant();
        Attempts updated = attempts.compute(key, (ignored, current) -> {
            if (current == null || now.isAfter(current.windowStartedAt().plus(window))) {
                return new Attempts(1, now, null);
            }
            int failures = current.failures() + 1;
            Instant lockedUntil = failures >= maximumFailures ? now.plus(lockDuration) : current.lockedUntil();
            return new Attempts(failures, current.windowStartedAt(), lockedUntil);
        });
        if (updated.lockedUntil() != null && now.isBefore(updated.lockedUntil())) {
            throw throttled();
        }
    }

    public void recordSuccess(String email) {
        attempts.remove(normalize(email));
    }

    private String normalize(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }

    private PasswordResetException throttled() {
        return new PasswordResetException(HttpStatus.TOO_MANY_REQUESTS,
                "Too many sign-in attempts. Please try again later");
    }

    private record Attempts(int failures, Instant windowStartedAt, Instant lockedUntil) { }
}
