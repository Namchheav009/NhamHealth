package com.nhamhealth.nhamhealth_api.service.auth;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.HexFormat;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.entity.RefreshToken;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.exception.PasswordResetException;
import com.nhamhealth.nhamhealth_api.repository.auth.RefreshTokenRepository;

@Service
public class RefreshTokenService {
    private final RefreshTokenRepository tokens;
    private final Duration expiration;
    private final SecureRandom random = new SecureRandom();

    public RefreshTokenService(
            RefreshTokenRepository tokens,
            @Value("${app.auth.refresh-token.expiration:P30D}") Duration expiration) {
        this.tokens = tokens;
        this.expiration = expiration;
    }

    @Transactional
    public IssuedRefreshToken issue(User user) {
        return create(user, LocalDateTime.now());
    }

    @Transactional(noRollbackFor = PasswordResetException.class)
    public RotatedRefreshToken rotate(String rawToken) {
        RefreshToken current = tokens.findByTokenHash(hash(rawToken)).orElseThrow(this::invalid);
        LocalDateTime now = LocalDateTime.now();
        if (current.getRevokedAt() != null) {
            revokeAll(current.getUser(), now);
            throw invalid();
        }
        if (!current.getExpiresAt().isAfter(now)) {
            current.setRevokedAt(now);
            tokens.save(current);
            throw invalid();
        }
        User user = current.getUser();
        if (!"ACTIVE".equalsIgnoreCase(user.getStatus()) || !Boolean.TRUE.equals(user.getIsVerified())) {
            revokeAll(user, now);
            throw invalid();
        }
        IssuedRefreshToken replacement = create(user, now);
        current.setRevokedAt(now);
        current.setReplacedByHash(hash(replacement.value()));
        tokens.save(current);
        return new RotatedRefreshToken(user, replacement);
    }

    @Transactional
    public void revokeForLogout(String rawToken) {
        tokens.findByTokenHash(hash(rawToken)).ifPresent(token -> {
            LocalDateTime now = LocalDateTime.now();
            if (token.getRevokedAt() == null) token.setRevokedAt(now);
            token.getUser().setLoginOtpRequired(true);
            revokeAll(token.getUser(), now);
        });
    }

    @Transactional
    public void revokeAll(User user) {
        revokeAll(user, LocalDateTime.now());
    }

    private IssuedRefreshToken create(User user, LocalDateTime now) {
        byte[] bytes = new byte[32];
        random.nextBytes(bytes);
        String raw = HexFormat.of().formatHex(bytes);
        RefreshToken token = new RefreshToken();
        token.setUser(user);
        token.setTokenHash(hash(raw));
        token.setCreatedAt(now);
        token.setExpiresAt(now.plus(expiration));
        tokens.save(token);
        return new IssuedRefreshToken(raw, expiration.toSeconds());
    }

    private void revokeAll(User user, LocalDateTime now) {
        tokens.findByUserAndRevokedAtIsNull(user).forEach(token -> token.setRevokedAt(now));
    }

    private String hash(String value) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is unavailable", exception);
        }
    }

    private PasswordResetException invalid() {
        return new PasswordResetException(HttpStatus.UNAUTHORIZED, "The refresh session is invalid or expired");
    }

    public record IssuedRefreshToken(String value, long expiresIn) { }
    public record RotatedRefreshToken(User user, IssuedRefreshToken token) { }
}
