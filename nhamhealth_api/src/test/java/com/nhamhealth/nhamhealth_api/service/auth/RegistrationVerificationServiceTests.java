package com.nhamhealth.nhamhealth_api.service.auth;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.security.crypto.password.PasswordEncoder;

import com.nhamhealth.nhamhealth_api.dto.request.RegisterRequest;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.entity.VerificationCode;
import com.nhamhealth.nhamhealth_api.exception.PasswordResetException;
import com.nhamhealth.nhamhealth_api.repository.auth.VerificationCodeRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserProfileRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.service.sms.PlasgateSmsService;

class RegistrationVerificationServiceTests {

    private AuthService authService;
    private UserRepository userRepository;
    private UserProfileRepository userProfileRepository;
    private VerificationCodeRepository codes;
    private PasswordEncoder passwordEncoder;
    private ObjectProvider<JavaMailSender> mailSenderProvider;
    private PlasgateSmsService smsService;
    private RegistrationVerificationService service;

    @BeforeEach
    @SuppressWarnings("unchecked")
    void setUp() {
        authService = mock(AuthService.class);
        userRepository = mock(UserRepository.class);
        userProfileRepository = mock(UserProfileRepository.class);
        codes = mock(VerificationCodeRepository.class);
        passwordEncoder = mock(PasswordEncoder.class);
        mailSenderProvider = mock(ObjectProvider.class);
        smsService = mock(PlasgateSmsService.class);

        when(smsService.normalizePhoneNumber("012345678")).thenReturn("85512345678");
        when(smsService.normalizePhoneNumber("85512345678")).thenReturn("85512345678");
        when(smsService.sendSms(anyString(), anyString())).thenReturn(true);
        when(passwordEncoder.encode(anyString())).thenReturn("hashed-otp");

        service = new RegistrationVerificationService(
                authService,
                userRepository,
                userProfileRepository,
                codes,
                passwordEncoder,
                mailSenderProvider,
                smsService,
                "no-reply@nhamhealth.com",
                Duration.ofMinutes(5),
                Duration.ofMinutes(1),
                5);
    }

    @Test
    void registerWithPhoneDispatchesSmsOtp() {
        User user = new User();
        user.setPhoneNumber("85512345678");
        user.setIsVerified(false);
        user.setStatus("PENDING");

        RegisterRequest request = new RegisterRequest("Visal", "012345678", "password123");
        when(authService.registerPendingMobileUser(request)).thenReturn(user);

        service.register(request);

        verify(smsService).sendSms(eq("85512345678"), contains("verification code"));
        verify(codes).save(any(VerificationCode.class));
    }

    @Test
    void registerWithPhoneReportsSmsDeliveryFailure() {
        User user = new User();
        user.setPhoneNumber("85512345678");
        user.setIsVerified(false);
        user.setStatus("PENDING");

        RegisterRequest request = new RegisterRequest("Visal", "012345678", "password123");
        when(authService.registerPendingMobileUser(request)).thenReturn(user);
        when(smsService.sendSms(anyString(), anyString())).thenReturn(false);

        assertThatThrownBy(() -> service.register(request))
                .isInstanceOf(PasswordResetException.class)
                .hasMessageContaining("could not send the SMS verification code");
    }

    @Test
    void verifyPhoneRegistrationActivatesUser() {
        User user = new User();
        user.setPhoneNumber("85512345678");

        VerificationCode code = new VerificationCode();
        code.setUser(user);
        code.setDestination("85512345678");
        code.setStatus("PENDING");
        code.setCodeHash("hashed-code");
        code.setExpiresAt(LocalDateTime.now().plusMinutes(5));
        code.setAttemptCount(0);

        when(codes.findFirstByDestinationIgnoreCaseAndPurposeOrderByCreatedAtDesc(eq("85512345678"), anyString()))
                .thenReturn(Optional.of(code));
        when(passwordEncoder.matches("123456", "hashed-code")).thenReturn(true);

        service.verify("012345678", "123456");

        assertThat(code.getStatus()).isEqualTo("VERIFIED");
        verify(authService).activateVerifiedUser(user);
    }
}
