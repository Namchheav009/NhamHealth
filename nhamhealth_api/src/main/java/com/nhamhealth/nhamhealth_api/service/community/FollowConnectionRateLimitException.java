package com.nhamhealth.nhamhealth_api.service.community;

public class FollowConnectionRateLimitException extends RuntimeException {
    private final long retryAfterSeconds;

    public FollowConnectionRateLimitException(long retryAfterSeconds) {
        super("Too many invitations. Try again later.");
        this.retryAfterSeconds = Math.max(1, retryAfterSeconds);
    }

    public long getRetryAfterSeconds() { return retryAfterSeconds; }
}
