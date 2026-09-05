package com.nhamhealth.nhamhealth_api.service.auth;

import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Locale;

import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.dto.response.EmailVerificationResponse;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.entity.VerificationCode;
import com.nhamhealth.nhamhealth_api.exception.PasswordResetException;
import com.nhamhealth.nhamhealth_api.repository.auth.VerificationCodeRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;

import jakarta.mail.internet.MimeMessage;

@Service
public class EmailChangeVerificationService {

    public static final String PURPOSE = "EMAIL_CHANGE";

    private final UserRepository users;
    private final VerificationCodeRepository codes;
    private final PasswordEncoder passwordEncoder;
    private final ObjectProvider<JavaMailSender> mailSenderProvider;
    private final SecureRandom random = new SecureRandom();
    private final String mailFrom;
    private final Duration codeTtl;
    private final Duration resendCooldown;
    private final int maximumAttempts;

    public EmailChangeVerificationService(
            UserRepository users,
            VerificationCodeRepository codes,
            PasswordEncoder passwordEncoder,
            ObjectProvider<JavaMailSender> mailSenderProvider,
            @Value("${app.mail.from:}") String mailFrom,
            @Value("${app.auth.otp.expiration:PT5M}") Duration codeTtl,
            @Value("${app.auth.otp.resend-cooldown:PT1M}") Duration resendCooldown,
            @Value("${app.auth.otp.maximum-attempts:5}") int maximumAttempts) {
        this.users = users;
        this.codes = codes;
        this.passwordEncoder = passwordEncoder;
        this.mailSenderProvider = mailSenderProvider;
        this.mailFrom = mailFrom;
        this.codeTtl = codeTtl;
        this.resendCooldown = resendCooldown;
        this.maximumAttempts = maximumAttempts;
    }

    @Transactional
    public EmailVerificationResponse sendVerificationCode(Integer userId, String rawEmail) {
        User user = requiredUser(userId);
        String email = normalize(rawEmail);
        ensureEmailAvailable(userId, email);
        LocalDateTime now = LocalDateTime.now();

        codes.findFirstByUserAndDestinationIgnoreCaseAndPurposeOrderByCreatedAtDesc(user, email, PURPOSE)
                .filter(latest -> latest.getCreatedAt().isAfter(now.minus(resendCooldown)))
                .ifPresent(latest -> {
                    throw new PasswordResetException(HttpStatus.TOO_MANY_REQUESTS,
                            "Please wait before requesting another verification code");
                });
        codes.findByDestinationIgnoreCaseAndPurposeAndStatus(email, PURPOSE, "PENDING")
                .forEach(existing -> existing.setStatus("SUPERSEDED"));

        String rawCode = String.format(Locale.ROOT, "%06d", random.nextInt(1_000_000));
        VerificationCode code = new VerificationCode();
        code.setUser(user);
        code.setDestination(email);
        code.setDeliveryMethod("EMAIL");
        code.setPurpose(PURPOSE);
        code.setCodeHash(passwordEncoder.encode(rawCode));
        code.setExpiresAt(now.plus(codeTtl));
        code.setAttemptCount(0);
        code.setStatus("PENDING");
        code.setCreatedAt(now);
        codes.save(code);
        deliver(email, rawCode);
        return new EmailVerificationResponse(true, "Verification code sent to your email", email, false);
    }

    @Transactional(noRollbackFor = PasswordResetException.class)
    public EmailVerificationResponse verifyCode(Integer userId, String rawEmail, String rawCode) {
        User user = requiredUser(userId);
        String email = normalize(rawEmail);
        LocalDateTime now = LocalDateTime.now();
        VerificationCode code = codes
                .findFirstByUserAndDestinationIgnoreCaseAndPurposeOrderByCreatedAtDesc(user, email, PURPOSE)
                .orElseThrow(this::invalidCode);
        if (!"PENDING".equals(code.getStatus())) throw invalidCode();
        if (code.getExpiresAt().isBefore(now)) {
            code.setStatus("EXPIRED");
            codes.save(code);
            throw new PasswordResetException(HttpStatus.BAD_REQUEST, "This verification code has expired");
        }
        if (code.getAttemptCount() >= maximumAttempts) {
            throw new PasswordResetException(HttpStatus.TOO_MANY_REQUESTS,
                    "Too many attempts. Please request a new verification code");
        }
        if (!passwordEncoder.matches(rawCode.trim(), code.getCodeHash())) {
            code.setAttemptCount(code.getAttemptCount() + 1);
            if (code.getAttemptCount() >= maximumAttempts) code.setStatus("LOCKED");
            codes.save(code);
            throw invalidCode();
        }

        ensureEmailAvailable(userId, email);
        code.setStatus("VERIFIED");
        code.setVerifiedAt(now);
        codes.save(code);
        user.setEmail(email);
        users.save(user);
        return new EmailVerificationResponse(true, "Email address verified successfully", email, true);
    }

    private User requiredUser(Integer userId) {
        return users.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
    }

    private void ensureEmailAvailable(Integer userId, String email) {
        users.findByEmailIgnoreCase(email)
                .filter(existing -> !existing.getUserId().equals(userId))
                .ifPresent(existing -> {
                    throw new IllegalArgumentException("That email address is already in use");
                });
    }

    private void deliver(String email, String code) {
        JavaMailSender sender = mailSenderProvider.getIfAvailable();
        if (sender == null) {
            throw new PasswordResetException(HttpStatus.SERVICE_UNAVAILABLE, "Email delivery is not configured");
        }
        try {
            MimeMessage message = sender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, StandardCharsets.UTF_8.name());
            if (!mailFrom.isBlank()) helper.setFrom(mailFrom, "NhamHealth");
            helper.setTo(email);
            helper.setSubject("%s is your NhamHealth verification code".formatted(code));
            helper.setText("Your NhamHealth email-change verification code is %s. It expires in 5 minutes."
                    .formatted(code));
            sender.send(message);
        } catch (Exception exception) {
            throw new PasswordResetException(HttpStatus.SERVICE_UNAVAILABLE,
                    "We could not send the verification email. Please try again shortly");
        }
    }

    private String normalize(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }

    private PasswordResetException invalidCode() {
        return new PasswordResetException(HttpStatus.BAD_REQUEST, "The verification code is incorrect");
    }
}
