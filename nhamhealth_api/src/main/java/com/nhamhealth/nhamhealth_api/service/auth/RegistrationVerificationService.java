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
import com.nhamhealth.nhamhealth_api.entity.UserProfile;
import com.nhamhealth.nhamhealth_api.entity.VerificationCode;
import com.nhamhealth.nhamhealth_api.exception.PasswordResetException;
import com.nhamhealth.nhamhealth_api.repository.auth.VerificationCodeRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserProfileRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.service.sms.PlasgateSmsService;

import jakarta.mail.internet.MimeMessage;

@Service
public class RegistrationVerificationService {
    private static final String PURPOSE = "EMAIL_VERIFICATION";
    private static final String LOGIN_PURPOSE = "LOGIN_VERIFICATION";

    private final AuthService authService;
    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;
    private final VerificationCodeRepository codes;
    private final PasswordEncoder passwordEncoder;
    private final ObjectProvider<JavaMailSender> mailSenderProvider;
    private final PlasgateSmsService smsService;
    private final SecureRandom random = new SecureRandom();
    private final String mailFrom;
    private final Duration codeTtl;
    private final Duration resendCooldown;
    private final int maximumAttempts;

    public RegistrationVerificationService(
            AuthService authService,
            UserRepository userRepository,
            UserProfileRepository userProfileRepository,
            VerificationCodeRepository codes,
            PasswordEncoder passwordEncoder,
            ObjectProvider<JavaMailSender> mailSenderProvider,
            PlasgateSmsService smsService,
            @Value("${app.mail.from:}") String mailFrom,
            @Value("${app.auth.otp.expiration:PT5M}") Duration codeTtl,
            @Value("${app.auth.otp.resend-cooldown:PT1M}") Duration resendCooldown,
            @Value("${app.auth.otp.maximum-attempts:5}") int maximumAttempts) {
        this.authService = authService;
        this.userRepository = userRepository;
        this.userProfileRepository = userProfileRepository;
        this.codes = codes;
        this.passwordEncoder = passwordEncoder;
        this.mailSenderProvider = mailSenderProvider;
        this.smsService = smsService;
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
    public void resend(String requestedIdentity) {
        User user = requiredPendingUser(requestedIdentity);
        sendCode(user, true, PURPOSE);
    }

    @Transactional
    public VerificationDestination sendLoginCode(
            User user,
            String requestedIdentity,
            boolean enforceCooldown) {
        VerificationDestination destination = loginDestination(user, requestedIdentity);
        sendCode(
                user,
                enforceCooldown,
                LOGIN_PURPOSE,
                destination.value(),
                destination.deliveryMethod());
        return destination;
    }

    @Transactional
    public void resendLoginCode(String requestedIdentity) {
        String raw = requestedIdentity == null ? "" : requestedIdentity.trim();
        boolean isPhone = !raw.contains("@") && raw.matches(".*\\d+.*");
        User user;
        if (isPhone) {
            String normalized = smsService.normalizePhoneNumber(raw);
            user = userRepository.findByPhoneNumber(normalized)
                    .or(() -> userRepository.findByPhoneNumber(raw))
                    .filter(candidate -> Boolean.TRUE.equals(candidate.getLoginOtpRequired()))
                    .filter(candidate -> "ACTIVE".equalsIgnoreCase(candidate.getStatus()))
                    .orElse(null);
        } else {
            user = userRepository.findByEmailIgnoreCase(normalize(raw))
                    .filter(candidate -> Boolean.TRUE.equals(candidate.getLoginOtpRequired()))
                    .filter(candidate -> "ACTIVE".equalsIgnoreCase(candidate.getStatus()))
                    .orElse(null);
        }

        if (user == null) {
            passwordEncoder.encode(String.format(Locale.ROOT, "%06d", random.nextInt(1_000_000)));
            return;
        }
        VerificationDestination destination = loginDestination(user, raw);
        sendCode(
                user,
                true,
                LOGIN_PURPOSE,
                destination.value(),
                destination.deliveryMethod());
    }

    @Transactional(noRollbackFor = PasswordResetException.class)
    public AuthResponse verify(String requestedIdentity, String rawCode) {
        return authService.activateVerifiedUser(verifyCode(requestedIdentity, rawCode, PURPOSE));
    }

    @Transactional(noRollbackFor = PasswordResetException.class)
    public AuthResponse verifyLogin(String requestedIdentity, String rawCode) {
        User user = verifyCode(requestedIdentity, rawCode, LOGIN_PURPOSE);
        if (!Boolean.TRUE.equals(user.getLoginOtpRequired())) throw invalidCode();
        return authService.completeLoginOtp(user);
    }

    private User verifyCode(String requestedIdentity, String rawCode, String purpose) {
        String raw = requestedIdentity == null ? "" : requestedIdentity.trim();
        boolean isPhone = !raw.contains("@") && raw.matches(".*\\d+.*");
        String destination = isPhone ? smsService.normalizePhoneNumber(raw) : normalize(raw);

        VerificationCode code = codes
                .findFirstByDestinationIgnoreCaseAndPurposeOrderByCreatedAtDesc(destination, purpose)
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
        if (!passwordEncoder.matches(rawCode.trim(), code.getCodeHash())) {
            int attempts = code.getAttemptCount() + 1;
            code.setAttemptCount(attempts);
            if (attempts >= maximumAttempts) code.setStatus("LOCKED");
            codes.save(code);
            if (attempts >= maximumAttempts) {
                throw new PasswordResetException(HttpStatus.TOO_MANY_REQUESTS, "Too many attempts. Request a new code");
            }
            throw invalidCode();
        }
        code.setStatus("VERIFIED");
        code.setVerifiedAt(now);
        codes.save(code);
        return code.getUser();
    }

    private void sendCode(User user, boolean enforceCooldown, String purpose) {
        String destination;
        String deliveryMethod;

        if (user.getPhoneNumber() != null && !user.getPhoneNumber().isBlank()) {
            destination = smsService.normalizePhoneNumber(user.getPhoneNumber());
            deliveryMethod = "SMS";
        } else if (user.getEmail() != null && !user.getEmail().isBlank()) {
            destination = normalize(user.getEmail());
            deliveryMethod = "EMAIL";
        } else {
            UserProfile profile = userProfileRepository.findByUser_UserId(user.getUserId()).orElse(null);
            if (profile != null && profile.getPhoneNumber() != null && !profile.getPhoneNumber().isBlank()) {
                destination = smsService.normalizePhoneNumber(profile.getPhoneNumber());
                deliveryMethod = "SMS";
            } else {
                throw new IllegalStateException("User does not have an email or phone number for verification");
            }
        }

        sendCode(user, enforceCooldown, purpose, destination, deliveryMethod);
    }

    private void sendCode(
            User user,
            boolean enforceCooldown,
            String purpose,
            String destination,
            String deliveryMethod) {
        LocalDateTime now = LocalDateTime.now();
        if (enforceCooldown) {
            codes.findFirstByDestinationIgnoreCaseAndPurposeOrderByCreatedAtDesc(destination, purpose)
                    .filter(latest -> "PENDING".equals(latest.getStatus()))
                    .filter(latest -> latest.getCreatedAt().isAfter(now.minus(resendCooldown)))
                    .ifPresent(latest -> {
                        throw new PasswordResetException(HttpStatus.TOO_MANY_REQUESTS,
                                "Please wait before requesting another code");
                    });
        }

        codes.findByDestinationIgnoreCaseAndPurposeAndStatus(destination, purpose, "PENDING")
                .forEach(existing -> existing.setStatus("SUPERSEDED"));

        String rawCode = String.format(Locale.ROOT, "%06d", random.nextInt(1_000_000));
        VerificationCode code = new VerificationCode();
        code.setUser(user);
        code.setDestination(destination);
        code.setDeliveryMethod(deliveryMethod);
        code.setPurpose(purpose);
        code.setCodeHash(passwordEncoder.encode(rawCode));
        code.setExpiresAt(now.plus(codeTtl));
        code.setAttemptCount(0);
        code.setStatus("PENDING");
        code.setCreatedAt(now);
        codes.save(code);

        if ("SMS".equals(deliveryMethod)) {
            String message = String.format(Locale.ROOT,
                    "Your NhamHealth verification code is %s. It expires in 5 minutes.", rawCode);
            if (!smsService.sendSms(destination, message)) {
                throw new PasswordResetException(
                        HttpStatus.SERVICE_UNAVAILABLE,
                        "We could not send the SMS verification code. Please try again shortly");
            }
        } else {
            deliver(destination, rawCode);
        }
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

    private User requiredPendingUser(String requestedIdentity) {
        String raw = requestedIdentity == null ? "" : requestedIdentity.trim();
        boolean isPhone = !raw.contains("@") && raw.matches(".*\\d+.*");
        User user;
        if (isPhone) {
            String normalized = smsService.normalizePhoneNumber(raw);
            user = userRepository.findByPhoneNumber(normalized)
                    .or(() -> userRepository.findByPhoneNumber(raw))
                    .orElse(null);
        } else {
            user = userRepository.findByEmailIgnoreCase(normalize(raw)).orElse(null);
        }

        if (user == null || Boolean.TRUE.equals(user.getIsVerified())) {
            throw new PasswordResetException(HttpStatus.BAD_REQUEST, "This account does not require verification");
        }
        return user;
    }

    private PasswordResetException invalidCode() {
        return new PasswordResetException(HttpStatus.BAD_REQUEST, "The verification code is incorrect");
    }

    private VerificationDestination loginDestination(User user, String requestedIdentity) {
        String raw = requestedIdentity == null ? "" : requestedIdentity.trim();
        if (raw.contains("@")) {
            String email = normalize(raw);
            if (user.getEmail() == null || !user.getEmail().equalsIgnoreCase(email)) {
                throw invalidCode();
            }
            return new VerificationDestination(email, "EMAIL");
        }

        String phone = smsService.normalizePhoneNumber(raw);
        String accountPhone = user.getPhoneNumber() == null
                ? ""
                : smsService.normalizePhoneNumber(user.getPhoneNumber());
        if (!phone.equals(accountPhone)) {
            throw invalidCode();
        }
        return new VerificationDestination(phone, "SMS");
    }

    private String normalize(String email) { return email.trim().toLowerCase(Locale.ROOT); }

    public record VerificationDestination(String value, String deliveryMethod) { }
}
