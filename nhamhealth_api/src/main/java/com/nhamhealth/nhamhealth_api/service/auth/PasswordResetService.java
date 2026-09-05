package com.nhamhealth.nhamhealth_api.service.auth;

import java.io.UnsupportedEncodingException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.Locale;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.mail.MailException;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.dto.response.PasswordResetVerificationResponse;
import com.nhamhealth.nhamhealth_api.entity.PasswordResetToken;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.entity.UserProfile;
import com.nhamhealth.nhamhealth_api.entity.VerificationCode;
import com.nhamhealth.nhamhealth_api.exception.PasswordResetException;
import com.nhamhealth.nhamhealth_api.repository.auth.PasswordResetTokenRepository;
import com.nhamhealth.nhamhealth_api.repository.auth.VerificationCodeRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserProfileRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.service.sms.PlasgateSmsService;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;

@Service
public class PasswordResetService {

    private static final Logger LOGGER = LoggerFactory.getLogger(PasswordResetService.class);
    private static final String PURPOSE = "PASSWORD_RESET";

    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;
    private final VerificationCodeRepository verificationCodeRepository;
    private final PasswordResetTokenRepository passwordResetTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final ObjectProvider<JavaMailSender> mailSenderProvider;
    private final PlasgateSmsService smsService;
    private final SecureRandom secureRandom = new SecureRandom();
    private final String mailFrom;
    private final Duration codeTtl;
    private final Duration tokenTtl;
    private final Duration resendCooldown;
    private final int maximumAttempts;
    private final RefreshTokenService refreshTokenService;

    public PasswordResetService(
            UserRepository userRepository,
            UserProfileRepository userProfileRepository,
            VerificationCodeRepository verificationCodeRepository,
            PasswordResetTokenRepository passwordResetTokenRepository,
            PasswordEncoder passwordEncoder,
            ObjectProvider<JavaMailSender> mailSenderProvider,
            PlasgateSmsService smsService,
            @Value("${app.mail.from:}") String mailFrom,
            @Value("${app.auth.otp.expiration:PT5M}") Duration codeTtl,
            @Value("${app.auth.password-reset.token-expiration:PT15M}") Duration tokenTtl,
            @Value("${app.auth.otp.resend-cooldown:PT1M}") Duration resendCooldown,
            @Value("${app.auth.otp.maximum-attempts:5}") int maximumAttempts,
            RefreshTokenService refreshTokenService) {
        this.userRepository = userRepository;
        this.userProfileRepository = userProfileRepository;
        this.verificationCodeRepository = verificationCodeRepository;
        this.passwordResetTokenRepository = passwordResetTokenRepository;
        this.passwordEncoder = passwordEncoder;
        this.mailSenderProvider = mailSenderProvider;
        this.smsService = smsService;
        this.mailFrom = mailFrom;
        this.codeTtl = codeTtl;
        this.tokenTtl = tokenTtl;
        this.resendCooldown = resendCooldown;
        this.maximumAttempts = maximumAttempts;
        this.refreshTokenService = refreshTokenService;
    }

    @Transactional
    public void sendCode(String requestedIdentity) {
        if (requestedIdentity == null || requestedIdentity.isBlank()) {
            return;
        }

        boolean isPhone = !requestedIdentity.contains("@") && requestedIdentity.matches(".*\\d+.*");
        String destination;
        String deliveryMethod;
        User user;

        if (isPhone) {
            destination = smsService.normalizePhoneNumber(requestedIdentity);
            deliveryMethod = "SMS";
            user = userRepository.findByPhoneNumber(destination)
                    .or(() -> userProfileRepository.findFirstByPhoneNumber(requestedIdentity.trim())
                            .or(() -> userProfileRepository.findFirstByPhoneNumber(destination))
                            .filter(profile -> Boolean.TRUE.equals(profile.getIsPhoneVerified()))
                            .map(UserProfile::getUser))
                    .orElse(null);
        } else {
            destination = normalizeEmail(requestedIdentity);
            deliveryMethod = "EMAIL";
            user = userRepository.findByEmailIgnoreCase(destination).orElse(null);
        }

        if (user == null) {
            passwordEncoder.encode(String.format(Locale.ROOT, "%06d", secureRandom.nextInt(1_000_000)));
            return;
        }

        LocalDateTime now = LocalDateTime.now();
        verificationCodeRepository
                .findFirstByDestinationIgnoreCaseAndPurposeOrderByCreatedAtDesc(destination, PURPOSE)
                .filter(latest -> "PENDING".equals(latest.getStatus()))
                .filter(latest -> latest.getCreatedAt().isAfter(now.minus(resendCooldown)))
                .ifPresent(latest -> {
                    throw new PasswordResetException(
                            HttpStatus.TOO_MANY_REQUESTS,
                            "Please wait before requesting another code");
                });

        verificationCodeRepository
                .findByDestinationIgnoreCaseAndPurposeAndStatus(destination, PURPOSE, "PENDING")
                .forEach(code -> code.setStatus("SUPERSEDED"));

        String rawCode = String.format(Locale.ROOT, "%06d", secureRandom.nextInt(1_000_000));
        VerificationCode verificationCode = new VerificationCode();
        verificationCode.setUser(user);
        verificationCode.setDestination(destination);
        verificationCode.setDeliveryMethod(deliveryMethod);
        verificationCode.setPurpose(PURPOSE);
        verificationCode.setCodeHash(passwordEncoder.encode(rawCode));
        verificationCode.setExpiresAt(now.plus(codeTtl));
        verificationCode.setAttemptCount(0);
        verificationCode.setStatus("PENDING");
        verificationCode.setCreatedAt(now);
        verificationCodeRepository.save(verificationCode);

        if ("SMS".equals(deliveryMethod)) {
            String message = String.format(Locale.ROOT,
                    "Your NhamHealth verification code is %s. It expires in 5 minutes.", rawCode);
            if (!smsService.sendSms(destination, message)) {
                throw new PasswordResetException(
                        HttpStatus.SERVICE_UNAVAILABLE,
                        "We could not send the SMS verification code. Please try again shortly");
            }
        } else {
            sendResetEmail(destination, rawCode);
        }
    }

    @Transactional(noRollbackFor = PasswordResetException.class)
    public PasswordResetVerificationResponse verifyCode(String requestedIdentity, String rawCode) {
        boolean isPhone = requestedIdentity != null && !requestedIdentity.contains("@") && requestedIdentity.matches(".*\\d+.*");
        String destination = isPhone ? smsService.normalizePhoneNumber(requestedIdentity) : normalizeEmail(requestedIdentity);

        VerificationCode verificationCode = verificationCodeRepository
                .findFirstByDestinationIgnoreCaseAndPurposeOrderByCreatedAtDesc(destination, PURPOSE)
                .orElseThrow(this::invalidCode);

        LocalDateTime now = LocalDateTime.now();

        if (!"PENDING".equals(verificationCode.getStatus())) {
            throw invalidCode();
        }
        if (verificationCode.getExpiresAt().isBefore(now)) {
            verificationCode.setStatus("EXPIRED");
            verificationCodeRepository.save(verificationCode);
            throw new PasswordResetException(HttpStatus.BAD_REQUEST, "This verification code has expired");
        }

        if (verificationCode.getAttemptCount() >= maximumAttempts) {
            verificationCode.setStatus("LOCKED");
            verificationCodeRepository.save(verificationCode);
            throw new PasswordResetException(
                    HttpStatus.TOO_MANY_REQUESTS,
                    "Too many incorrect attempts. Request a new code");
        }

        if (!passwordEncoder.matches(rawCode.trim(), verificationCode.getCodeHash())) {
            int attempts = verificationCode.getAttemptCount() + 1;
            verificationCode.setAttemptCount(attempts);
            if (attempts >= maximumAttempts) {
                verificationCode.setStatus("LOCKED");
            }
            verificationCodeRepository.save(verificationCode);
            if (attempts >= maximumAttempts) {
                throw new PasswordResetException(
                        HttpStatus.TOO_MANY_REQUESTS,
                        "Too many incorrect attempts. Request a new code");
            }
            throw invalidCode();
        }

        verificationCode.setVerifiedAt(now);
        verificationCode.setStatus("VERIFIED");
        verificationCodeRepository.save(verificationCode);

        User user = verificationCode.getUser();
        passwordResetTokenRepository.findByUserAndUsedAtIsNull(user).forEach(token -> token.setUsedAt(now));

        byte[] tokenBytes = new byte[32];
        secureRandom.nextBytes(tokenBytes);
        String rawToken = Base64.getUrlEncoder().withoutPadding().encodeToString(tokenBytes);
        PasswordResetToken resetToken = new PasswordResetToken();
        resetToken.setUser(user);
        resetToken.setTokenHash(sha256(rawToken));
        resetToken.setExpiresAt(now.plus(tokenTtl));
        resetToken.setCreatedAt(now);
        passwordResetTokenRepository.save(resetToken);

        return new PasswordResetVerificationResponse(rawToken, tokenTtl.toSeconds());
    }

    @Transactional
    public void resetPassword(String rawToken, String newPassword) {
        PasswordResetToken resetToken = passwordResetTokenRepository
                .findByTokenHashAndUsedAtIsNull(sha256(rawToken))
                .orElseThrow(() -> new PasswordResetException(
                        HttpStatus.BAD_REQUEST,
                        "This password reset session is invalid or has already been used"));
        LocalDateTime now = LocalDateTime.now();

        if (resetToken.getExpiresAt().isBefore(now)) {
            resetToken.setUsedAt(now);
            passwordResetTokenRepository.save(resetToken);
            throw new PasswordResetException(
                    HttpStatus.BAD_REQUEST,
                    "This password reset session has expired. Request a new code");
        }

        resetToken.setUsedAt(now);
        passwordResetTokenRepository.save(resetToken);

        User user = resetToken.getUser();
        user.setPasswordHash(passwordEncoder.encode(newPassword));
        userRepository.save(user);
        refreshTokenService.revokeAll(user);
        passwordResetTokenRepository.findByUserAndUsedAtIsNull(user).forEach(token -> token.setUsedAt(now));
        verificationCodeRepository
                .findByUserAndPurposeAndStatus(user, PURPOSE, "VERIFIED")
                .forEach(code -> code.setStatus("USED"));
    }

    private void sendResetEmail(String email, String code) {
        JavaMailSender mailSender = mailSenderProvider.getIfAvailable();
        if (mailSender == null) {
            throw new PasswordResetException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "Email delivery is not configured on the server");
        }

        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(
                    message, true, StandardCharsets.UTF_8.name());
            if (!mailFrom.isBlank()) {
                helper.setFrom(mailFrom, "NhamHealth");
            }
            helper.setTo(email);
            helper.setSubject(PasswordResetEmailTemplate.subject(code));
            helper.setText(
                    PasswordResetEmailTemplate.plainText(code),
                    PasswordResetEmailTemplate.html(code));
            mailSender.send(message);
        } catch (MailException | MessagingException | UnsupportedEncodingException exception) {
            LOGGER.error("Could not deliver a password reset email to {}", email, exception);
            throw new PasswordResetException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "We could not send the verification email. Please try again shortly");
        }
    }

    private PasswordResetException invalidCode() {
        return new PasswordResetException(HttpStatus.BAD_REQUEST, "The verification code is incorrect");
    }

    private String normalizeEmail(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }

    private String sha256(String value) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8));
            return Base64.getUrlEncoder().withoutPadding().encodeToString(digest);
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is unavailable", exception);
        }
    }
}
