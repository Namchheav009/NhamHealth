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

import com.nhamhealth.nhamhealth_api.dto.request.RegisterRequest;
import com.nhamhealth.nhamhealth_api.dto.response.AuthResponse;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.entity.VerificationCode;
import com.nhamhealth.nhamhealth_api.exception.PasswordResetException;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.repository.auth.VerificationCodeRepository;

import jakarta.mail.internet.MimeMessage;

@Service
public class RegistrationVerificationService {
    private static final String PURPOSE = "EMAIL_VERIFICATION";
    private static final String LOGIN_PURPOSE = "LOGIN_VERIFICATION";

    private final AuthService authService;
    private final UserRepository userRepository;
    private final VerificationCodeRepository codes;
    private final PasswordEncoder passwordEncoder;
    private final ObjectProvider<JavaMailSender> mailSenderProvider;
    private final SecureRandom random = new SecureRandom();
    private final String mailFrom;
    private final Duration codeTtl;
    private final Duration resendCooldown;
    private final int maximumAttempts;

    public RegistrationVerificationService(
            AuthService authService,
            UserRepository userRepository,
            VerificationCodeRepository codes,
            PasswordEncoder passwordEncoder,
            ObjectProvider<JavaMailSender> mailSenderProvider,
            @Value("${app.mail.from:}") String mailFrom,
            @Value("${app.auth.otp.expiration:PT5M}") Duration codeTtl,
            @Value("${app.auth.otp.resend-cooldown:PT1M}") Duration resendCooldown,
            @Value("${app.auth.otp.maximum-attempts:5}") int maximumAttempts) {
        this.authService = authService;
        this.userRepository = userRepository;
        this.codes = codes;
        this.passwordEncoder = passwordEncoder;
        this.mailSenderProvider = mailSenderProvider;
        this.mailFrom = mailFrom;
        this.codeTtl = codeTtl;
        this.resendCooldown = resendCooldown;
        this.maximumAttempts = maximumAttempts;
    }

    @Transactional
    public void register(RegisterRequest request) {
        User user = authService.registerPendingMobileUser(request);
        sendCode(user, false, PURPOSE);
    }

    @Transactional
    public void resend(String requestedEmail) {
        User user = requiredPendingUser(requestedEmail);
        sendCode(user, true, PURPOSE);
    }

    @Transactional
    public void sendLoginCode(User user, boolean enforceCooldown) {
        sendCode(user, enforceCooldown, LOGIN_PURPOSE);
    }

    @Transactional
    public void resendLoginCode(String requestedEmail) {
        User user = userRepository.findByEmailIgnoreCase(normalize(requestedEmail))
                .filter(candidate -> Boolean.TRUE.equals(candidate.getLoginOtpRequired()))
                .filter(candidate -> "ACTIVE".equalsIgnoreCase(candidate.getStatus()))
                .orElse(null);
        if (user == null) {
            passwordEncoder.encode(String.format(Locale.ROOT, "%04d", random.nextInt(10_000)));
            return;
        }
        sendCode(user, true, LOGIN_PURPOSE);
    }

    @Transactional(noRollbackFor = PasswordResetException.class)
    public AuthResponse verify(String requestedEmail, String rawCode) {
        return authService.activateVerifiedUser(verifyCode(requestedEmail, rawCode, PURPOSE));
    }

    @Transactional(noRollbackFor = PasswordResetException.class)
    public AuthResponse verifyLogin(String requestedEmail, String rawCode) {
        User user = verifyCode(requestedEmail, rawCode, LOGIN_PURPOSE);
        if (!Boolean.TRUE.equals(user.getLoginOtpRequired())) throw invalidCode();
        return authService.completeLoginOtp(user);
    }

    private User verifyCode(String requestedEmail, String rawCode, String purpose) {
        String email = normalize(requestedEmail);
        VerificationCode code = codes
                .findFirstByDestinationIgnoreCaseAndPurposeOrderByCreatedAtDesc(email, purpose)
                .orElseThrow(this::invalidCode);
        LocalDateTime now = LocalDateTime.now();
        if (!"PENDING".equals(code.getStatus())) throw invalidCode();
        if (code.getExpiresAt().isBefore(now)) {
            code.setStatus("EXPIRED");
            codes.save(code);
            throw new PasswordResetException(HttpStatus.BAD_REQUEST, "This verification code has expired");
        }
        if (code.getAttemptCount() >= maximumAttempts) {
            throw new PasswordResetException(HttpStatus.TOO_MANY_REQUESTS, "Too many attempts. Request a new code");
        }
        if (!passwordEncoder.matches(rawCode, code.getCodeHash())) {
            code.setAttemptCount(code.getAttemptCount() + 1);
            if (code.getAttemptCount() >= maximumAttempts) code.setStatus("LOCKED");
            codes.save(code);
            throw invalidCode();
        }
        code.setStatus("VERIFIED");
        code.setVerifiedAt(now);
        codes.save(code);
        return code.getUser();
    }

    private void sendCode(User user, boolean enforceCooldown, String purpose) {
        String email = user.getEmail();
        LocalDateTime now = LocalDateTime.now();
        if (enforceCooldown) {
            codes.findFirstByDestinationIgnoreCaseAndPurposeOrderByCreatedAtDesc(email, purpose)
                    .filter(latest -> latest.getCreatedAt().isAfter(now.minus(resendCooldown)))
                    .ifPresent(latest -> { throw new PasswordResetException(HttpStatus.TOO_MANY_REQUESTS, "Please wait before requesting another code"); });
        }
        codes.findByDestinationIgnoreCaseAndPurposeAndStatus(email, purpose, "PENDING")
                .forEach(existing -> existing.setStatus("SUPERSEDED"));
        String rawCode = String.format(Locale.ROOT, "%04d", random.nextInt(10_000));
        VerificationCode code = new VerificationCode();
        code.setUser(user);
        code.setDestination(email);
        code.setDeliveryMethod("EMAIL");
        code.setPurpose(purpose);
        code.setCodeHash(passwordEncoder.encode(rawCode));
        code.setExpiresAt(now.plus(codeTtl));
        code.setAttemptCount(0);
        code.setStatus("PENDING");
        code.setCreatedAt(now);
        codes.save(code);
        deliver(email, rawCode);
    }

    private void deliver(String email, String code) {
        JavaMailSender sender = mailSenderProvider.getIfAvailable();
        if (sender == null) throw new PasswordResetException(HttpStatus.SERVICE_UNAVAILABLE, "Email delivery is not configured");
        try {
            MimeMessage message = sender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, StandardCharsets.UTF_8.name());
            if (!mailFrom.isBlank()) helper.setFrom(mailFrom, "NhamHealth");
            helper.setTo(email);
            helper.setSubject("%s is your NhamHealth verification code".formatted(code));
            helper.setText("Your NhamHealth email verification code is %s. It expires in 5 minutes.".formatted(code));
            sender.send(message);
        } catch (Exception exception) {
            throw new PasswordResetException(HttpStatus.SERVICE_UNAVAILABLE, "We could not send the verification email. Please try again shortly");
        }
    }

    private User requiredPendingUser(String email) {
        return userRepository.findByEmailIgnoreCase(normalize(email))
                .filter(user -> !Boolean.TRUE.equals(user.getIsVerified()))
                .orElseThrow(() -> new PasswordResetException(HttpStatus.BAD_REQUEST, "This account does not require verification"));
    }

    private PasswordResetException invalidCode() {
        return new PasswordResetException(HttpStatus.BAD_REQUEST, "The verification code is incorrect");
    }

    private String normalize(String email) { return email.trim().toLowerCase(Locale.ROOT); }
}
