package com.nhamhealth.nhamhealth_api.service.auth;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Collections;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import org.springframework.security.crypto.password.PasswordEncoder;

import com.nhamhealth.nhamhealth_api.dto.response.PhoneVerificationResponse;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.entity.UserProfile;
import com.nhamhealth.nhamhealth_api.entity.VerificationCode;
import com.nhamhealth.nhamhealth_api.exception.PasswordResetException;
import com.nhamhealth.nhamhealth_api.repository.auth.VerificationCodeRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserProfileRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.service.sms.PlasgateSmsService;

class PhoneVerificationServiceTests {

    private UserRepository userRepository;
    private UserProfileRepository userProfileRepository;
    private VerificationCodeRepository verificationCodeRepository;
    private PasswordEncoder passwordEncoder;
    private PlasgateSmsService smsService;
    private PhoneVerificationService phoneVerificationService;

    @BeforeEach
    void setUp() {
        userRepository = mock(UserRepository.class);
        userProfileRepository = mock(UserProfileRepository.class);
        verificationCodeRepository = mock(VerificationCodeRepository.class);
        passwordEncoder = mock(PasswordEncoder.class);
        smsService = mock(PlasgateSmsService.class);

        when(smsService.normalizePhoneNumber("012345678")).thenReturn("85512345678");

        phoneVerificationService = new PhoneVerificationService(
                userRepository,
                userProfileRepository,
                verificationCodeRepository,
                passwordEncoder,
                smsService,
                Duration.ofMinutes(5),
                Duration.ofMinutes(1),
                5);
    }

    @Test
    void sendVerificationCodeSuccessfullyDispatchesSms() {
        User user = new User();
        when(userRepository.findById(1)).thenReturn(Optional.of(user));
        when(verificationCodeRepository.findFirstByDestinationIgnoreCaseAndPurposeOrderByCreatedAtDesc(
                eq("85512345678"), eq(PhoneVerificationService.PURPOSE)))
                .thenReturn(Optional.empty());
        when(verificationCodeRepository.findByDestinationIgnoreCaseAndPurposeAndStatus(
                eq("85512345678"), eq(PhoneVerificationService.PURPOSE), eq("PENDING")))
                .thenReturn(Collections.emptyList());
        when(passwordEncoder.encode(anyString())).thenReturn("hashed-otp");
        when(smsService.sendSms(eq("85512345678"), anyString())).thenReturn(true);

        PhoneVerificationResponse response = phoneVerificationService.sendVerificationCode(1, "012345678");

        assertThat(response.success()).isTrue();
        assertThat(response.phone()).isEqualTo("85512345678");
        assertThat(response.verified()).isFalse();

        verify(smsService).sendSms(
                eq("85512345678"),
                argThat(message -> message.matches(".*verification code is \\d{6}\\..*")));
        verify(verificationCodeRepository).save(any(VerificationCode.class));
    }

    @Test
    void verifyCodeSuccessfullyMarksProfileAsVerified() {
        User user = new User();
        UserProfile profile = new UserProfile();
        profile.setUser(user);

        VerificationCode code = new VerificationCode();
        code.setUser(user);
        code.setStatus("PENDING");
        code.setExpiresAt(LocalDateTime.now().plusMinutes(5));
        code.setAttemptCount(0);
        code.setCodeHash("hashed-123456");

        when(verificationCodeRepository.findFirstByUserAndDestinationIgnoreCaseAndPurposeOrderByCreatedAtDesc(
                eq(user), eq("85512345678"), eq(PhoneVerificationService.PURPOSE)))
                .thenReturn(Optional.of(code));
        when(passwordEncoder.matches("123456", "hashed-123456")).thenReturn(true);
        when(userRepository.findById(1)).thenReturn(Optional.of(user));
        when(userProfileRepository.findByUser_UserId(1)).thenReturn(Optional.of(profile));

        PhoneVerificationResponse response = phoneVerificationService.verifyCode(1, "012345678", "123456");

        assertThat(response.success()).isTrue();
        assertThat(response.verified()).isTrue();
        assertThat(profile.getIsPhoneVerified()).isTrue();
        assertThat(profile.getPhoneNumber()).isEqualTo("85512345678");
        assertThat(user.getPhoneNumber()).isEqualTo("85512345678");
        assertThat(code.getStatus()).isEqualTo("VERIFIED");

        verify(userRepository).save(user);
        verify(userProfileRepository).save(profile);
    }

    @Test
    void verifyCodeThrowsOnIncorrectCode() {
        VerificationCode code = new VerificationCode();
        User user = new User();
        code.setUser(user);
        code.setStatus("PENDING");
        code.setExpiresAt(LocalDateTime.now().plusMinutes(5));
        code.setAttemptCount(0);
        code.setCodeHash("hashed-123456");

        when(userRepository.findById(1)).thenReturn(Optional.of(user));
        when(verificationCodeRepository.findFirstByUserAndDestinationIgnoreCaseAndPurposeOrderByCreatedAtDesc(
                eq(user), eq("85512345678"), eq(PhoneVerificationService.PURPOSE)))
                .thenReturn(Optional.of(code));
        when(passwordEncoder.matches("999999", "hashed-123456")).thenReturn(false);

        assertThatThrownBy(() -> phoneVerificationService.verifyCode(1, "012345678", "999999"))
                .isInstanceOf(PasswordResetException.class)
                .hasMessageContaining("incorrect");

        assertThat(code.getAttemptCount()).isEqualTo(1);
    }
}
