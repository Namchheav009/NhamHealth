package com.nhamhealth.nhamhealth_api.service.auth;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Locale;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.dto.response.PhoneVerificationResponse;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.entity.UserProfile;
import com.nhamhealth.nhamhealth_api.entity.VerificationCode;
import com.nhamhealth.nhamhealth_api.exception.PasswordResetException;
import com.nhamhealth.nhamhealth_api.repository.auth.VerificationCodeRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserProfileRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.service.sms.PlasgateSmsService;

@Service
public class PhoneVerificationService {

    public static final String PURPOSE = "PHONE_VERIFICATION";

    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;
    private final VerificationCodeRepository verificationCodeRepository;
    private final PasswordEncoder passwordEncoder;
    private final PlasgateSmsService smsService;
    private final SecureRandom random = new SecureRandom();

    private final Duration codeTtl;
    private final Duration resendCooldown;
    private final int maximumAttempts;

    public PhoneVerificationService(
            UserRepository userRepository,
            UserProfileRepository userProfileRepository,
            VerificationCodeRepository verificationCodeRepository,
            PasswordEncoder passwordEncoder,
            PlasgateSmsService smsService,
            @Value("${app.auth.otp.expiration:PT5M}") Duration codeTtl,
            @Value("${app.auth.otp.resend-cooldown:PT1M}") Duration resendCooldown,
            @Value("${app.auth.otp.maximum-attempts:5}") int maximumAttempts) {
        this.userRepository = userRepository;
        this.userProfileRepository = userProfileRepository;
        this.verificationCodeRepository = verificationCodeRepository;
        this.passwordEncoder = passwordEncoder;
        this.smsService = smsService;
        this.codeTtl = codeTtl;
        this.resendCooldown = resendCooldown;
        this.maximumAttempts = maximumAttempts;
    }

    @Transactional
    public PhoneVerificationResponse sendVerificationCode(Integer userId, String rawPhone) {
        String normalized = smsService.normalizePhoneNumber(rawPhone);
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        LocalDateTime now = LocalDateTime.now();

        verificationCodeRepository
                .findFirstByDestinationIgnoreCaseAndPurposeOrderByCreatedAtDesc(normalized, PURPOSE)
                .filter(latest -> latest.getCreatedAt().isAfter(now.minus(resendCooldown)))
                .ifPresent(latest -> {
                    throw new PasswordResetException(HttpStatus.TOO_MANY_REQUESTS,
                            "Please wait before requesting another verification code");
                });

        verificationCodeRepository
                .findByDestinationIgnoreCaseAndPurposeAndStatus(normalized, PURPOSE, "PENDING")
                .forEach(existing -> existing.setStatus("SUPERSEDED"));

        String rawCode = String.format(Locale.ROOT, "%06d", random.nextInt(1_000_000));

        VerificationCode code = new VerificationCode();
        code.setUser(user);
        code.setDestination(normalized);
        code.setDeliveryMethod("SMS");
        code.setPurpose(PURPOSE);
        code.setCodeHash(passwordEncoder.encode(rawCode));
        code.setExpiresAt(now.plus(codeTtl));
        code.setAttemptCount(0);
        code.setStatus("PENDING");
        code.setCreatedAt(now);
        verificationCodeRepository.save(code);

        String message = String.format(Locale.ROOT,
                "Your NhamHealth verification code is %s. It expires in 5 minutes.", rawCode);

        boolean sent = smsService.sendSms(normalized, message);
        if (!sent) {
            throw new PasswordResetException(HttpStatus.SERVICE_UNAVAILABLE,
                    "We could not send the SMS verification code. Please check your phone number and try again.");
        }

        return new PhoneVerificationResponse(true, "Verification code sent to your phone", normalized, false);
    }

    @Transactional(noRollbackFor = PasswordResetException.class)
    public PhoneVerificationResponse verifyCode(Integer userId, String rawPhone, String rawCode) {
        String normalized = smsService.normalizePhoneNumber(rawPhone);
        LocalDateTime now = LocalDateTime.now();

        VerificationCode code = verificationCodeRepository
                .findFirstByDestinationIgnoreCaseAndPurposeOrderByCreatedAtDesc(normalized, PURPOSE)
                .orElseThrow(this::invalidCode);

        if (!"PENDING".equals(code.getStatus())) {
            throw invalidCode();
        }

        if (code.getExpiresAt().isBefore(now)) {
            code.setStatus("EXPIRED");
            verificationCodeRepository.save(code);
            throw new PasswordResetException(HttpStatus.BAD_REQUEST, "This verification code has expired");
        }

        if (code.getAttemptCount() >= maximumAttempts) {
            throw new PasswordResetException(HttpStatus.TOO_MANY_REQUESTS,
                    "Too many attempts. Please request a new verification code");
        }

        if (!passwordEncoder.matches(rawCode.trim(), code.getCodeHash())) {
            code.setAttemptCount(code.getAttemptCount() + 1);
            if (code.getAttemptCount() >= maximumAttempts) {
                code.setStatus("LOCKED");
            }
            verificationCodeRepository.save(code);
            throw invalidCode();
        }

        code.setStatus("VERIFIED");
        code.setVerifiedAt(now);
        verificationCodeRepository.save(code);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        UserProfile profile = userProfileRepository.findByUser_UserId(userId)
                .orElseGet(() -> {
                    UserProfile created = new UserProfile();
                    created.setUser(user);
                    created.setFullName("User");
                    created.setCreatedAt(now);
                    return created;
                });

        profile.setPhoneNumber(rawPhone.trim());
        profile.setIsPhoneVerified(true);
        profile.setPhoneVerifiedAt(now);
        profile.setUpdatedAt(now);
        userProfileRepository.save(profile);

        return new PhoneVerificationResponse(true, "Phone number verified successfully", normalized, true);
    }

    private PasswordResetException invalidCode() {
        return new PasswordResetException(HttpStatus.BAD_REQUEST, "The verification code is incorrect");
    }
}
