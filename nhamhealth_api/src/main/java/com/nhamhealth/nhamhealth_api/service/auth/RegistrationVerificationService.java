package com.nhamhealth.nhamhealth_api.service.auth;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Locale;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
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
import com.nhamhealth.nhamhealth_api.service.email.BrevoEmailService;

@Service
public class RegistrationVerificationService {
    private static final Logger LOGGER = LoggerFactory.getLogger(RegistrationVerificationService.class);
    private static final String PURPOSE = "EMAIL_VERIFICATION";
    private static final String LOGIN_PURPOSE = "LOGIN_VERIFICATION";

    private final AuthService authService;
    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;
    private final VerificationCodeRepository codes;
    private final PasswordEncoder passwordEncoder;
    private final BrevoEmailService brevoEmailService;
    private final PlasgateSmsService smsService;
    private final SecureRandom random = new SecureRandom();
    private final String mailFrom;
    private final Duration codeTtl;
    private final Duration resendCooldown;
    private final int maximumAttempts;
    private final boolean fallbackToConsole;

    @Autowired
    public RegistrationVerificationService(
            AuthService authService,
            UserRepository userRepository,
            UserProfileRepository userProfileRepository,
            VerificationCodeRepository codes,
            PasswordEncoder passwordEncoder,
            BrevoEmailService brevoEmailService,
            PlasgateSmsService smsService,
            @Value("${app.mail.from:${spring.mail.username:}}") String mailFrom,
            @Value("${app.auth.otp.expiration:PT5M}") Duration codeTtl,
            @Value("${app.auth.otp.resend-cooldown:PT1M}") Duration resendCooldown,
            @Value("${app.auth.otp.maximum-attempts:5}") int maximumAttempts,
            @Value("${app.mail.fallback-to-console:false}") boolean fallbackToConsole) {
        this.authService = authService;
        this.userRepository = userRepository;
        this.userProfileRepository = userProfileRepository;
        this.codes = codes;
        this.passwordEncoder = passwordEncoder;
        this.brevoEmailService = brevoEmailService;
        this.smsService = smsService;
        this.mailFrom = mailFrom;
        this.codeTtl = codeTtl;
        this.resendCooldown = resendCooldown;
        this.maximumAttempts = maximumAttempts;
        this.fallbackToConsole = fallbackToConsole;
    }

    public RegistrationVerificationService(
            AuthService authService,
            UserRepository userRepository,
            UserProfileRepository userProfileRepository,
            VerificationCodeRepository codes,
            PasswordEncoder passwordEncoder,
            BrevoEmailService brevoEmailService,
            PlasgateSmsService smsService,
            String mailFrom,
            Duration codeTtl,
            Duration resendCooldown,
            int maximumAttempts) {
        this(authService, userRepository, userProfileRepository, codes, passwordEncoder,
                brevoEmailService, smsService, mailFrom, codeTtl, resendCooldown, maximumAttempts, false);
    }

    public RegistrationVerificationService(
            AuthService authService,
            UserRepository userRepository,
            UserProfileRepository userProfileRepository,
            VerificationCodeRepository codes,
            PasswordEncoder passwordEncoder,
            org.springframework.beans.factory.ObjectProvider<?> ignoredMailSenderProvider,
            PlasgateSmsService smsService,
            String mailFrom,
            Duration codeTtl,
            Duration resendCooldown,
            int maximumAttempts) {
        this(authService, userRepository, userProfileRepository, codes, passwordEncoder,
                null, smsService, mailFrom, codeTtl, resendCooldown, maximumAttempts, false);
    }

    @Transactional
    public void register(RegisterRequest request) {
        User user = authService.registerPendingMobileUser(request);
        String raw = request.email() == null ? "" : request.email().trim();
        boolean isPhone = !raw.contains("@") && raw.matches(".*\\d+.*");
        if (isPhone) {
            sendCode(user, false, PURPOSE, smsService.normalizePhoneNumber(raw), "SMS");
        } else {
            sendCode(user, false, PURPOSE, normalize(raw), "EMAIL");
        }
    }

    @Transactional
    public AuthService.MobileLoginResult loginWithGoogle(String idToken) {
        var result = authService.loginWithGoogle(idToken);
        if (result.otpRequired()) {
            String email = normalize(result.otpUser().getEmail());
            boolean hasUsableCode = codes
                    .findFirstByDestinationIgnoreCaseAndPurposeOrderByCreatedAtDesc(email, PURPOSE)
                    .filter(latest -> "PENDING".equals(latest.getStatus()))
                    .filter(latest -> latest.getExpiresAt().isAfter(LocalDateTime.now()))
                    .isPresent();
            if (!hasUsableCode) {
                sendCode(result.otpUser(), false, PURPOSE, email, "EMAIL");
            }
        }
        return result;
    }

    @Transactional
    public void resend(String requestedIdentity) {
        User user = requiredPendingUser(requestedIdentity);
        String raw = requestedIdentity == null ? "" : requestedIdentity.trim();
        boolean isPhone = !raw.contains("@") && raw.matches(".*\\d+.*");
        if (isPhone) {
            sendCode(user, true, PURPOSE, smsService.normalizePhoneNumber(raw), "SMS");
        } else {
            sendCode(user, true, PURPOSE, normalize(raw), "EMAIL");
        }
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
        if (!Boolean.TRUE.equals(user.getLoginOtpRequired()))
            throw invalidCode();
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
        if (!"PENDING".equals(code.getStatus()))
            throw invalidCode();
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
            if (attempts >= maximumAttempts)
                code.setStatus("LOCKED");
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
        deliverPending(createCode(user, enforceCooldown, purpose, destination, deliveryMethod));
    }

    private PendingCode createCode(
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

        return new PendingCode(destination, deliveryMethod, rawCode, purpose);
    }

    private void deliverPending(PendingCode pending) {
        if ("SMS".equals(pending.deliveryMethod())) {
            String message = String.format(Locale.ROOT,
                    "Your NhamHealth verification code is %s. It expires in 5 minutes.", pending.rawCode());
            if (!smsService.sendSms(pending.destination(), message)) {
                throw new PasswordResetException(
                        HttpStatus.SERVICE_UNAVAILABLE,
                        "We could not send the SMS verification code. Please try again shortly");
            }
        } else {
            deliver(pending.destination(), pending.rawCode(), LOGIN_PURPOSE.equals(pending.purpose()));
        }
    }

    private void deliver(String email, String code, boolean isLogin) {
        try {
            brevoEmailService.sendEmail(
                    email,
                    EmailVerificationTemplate.subject(code, isLogin),
                    EmailVerificationTemplate.plainText(code, isLogin),
                    EmailVerificationTemplate.html(code, isLogin));
            LOGGER.info("Verification code email successfully sent to {}", email);
        } catch (Exception exception) {
            LOGGER.error("Could not deliver a verification code email to {}", email, exception);
            if (fallbackToConsole) {
                LOGGER.warn("==================================================================");
                LOGGER.warn(" [EMAIL FALLBACK OTP] Verification code for {}: {}", email, code);
                LOGGER.warn("==================================================================");
                return;
            }
                throw new PasswordResetException(HttpStatus.SERVICE_UNAVAILABLE,
                    "We could not send the verification email. Please try again shortly");
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

    private String normalize(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }

    public record VerificationDestination(String value, String deliveryMethod) {
    }

    private record PendingCode(String destination, String deliveryMethod, String rawCode, String purpose) {
    }
}
