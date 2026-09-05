package com.nhamhealth.nhamhealth_api.service.sms;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class PlasgateSmsServiceTests {

    private PlasgateSmsService service;

    @BeforeEach
    void setUp() {
        service = new PlasgateSmsService(
                "https://cloudapi.plasgate.com",
                "test-private-key",
                "test-secret-key",
                "Nham Health",
                "SMS Info",
                true);
    }

    @Test
    void normalizesLocalCambodianPhoneNumberWithLeadingZero() {
        String normalized = service.normalizePhoneNumber("012 345 678");
        assertThat(normalized).isEqualTo("85512345678");
    }

    @Test
    void normalizesPhoneNumberWithPlusAndSpaces() {
        String normalized = service.normalizePhoneNumber("+855 96 123 4567");
        assertThat(normalized).isEqualTo("855961234567");
    }

    @Test
    void preservesExistingEightFiveFivePrefix() {
        String normalized = service.normalizePhoneNumber("85512345678");
        assertThat(normalized).isEqualTo("85512345678");
    }

    @Test
    void prependsCountryCodeForStandardLocalDigitsWithoutZero() {
        String normalized = service.normalizePhoneNumber("12345678");
        assertThat(normalized).isEqualTo("85512345678");
    }

    @Test
    void rejectsEmptyOrInvalidPhoneNumber() {
        assertThatThrownBy(() -> service.normalizePhoneNumber(""))
                .isInstanceOf(IllegalArgumentException.class);

        assertThatThrownBy(() -> service.normalizePhoneNumber("abc"))
                .isInstanceOf(IllegalArgumentException.class);

        assertThatThrownBy(() -> service.normalizePhoneNumber("123"))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void masksPhoneNumberProperly() {
        String masked = PlasgateSmsService.maskPhone("85512345678");
        assertThat(masked).isEqualTo("855****678");
    }

    @Test
    void returnsTrueWhenSmsIsDisabled() {
        PlasgateSmsService disabledService = new PlasgateSmsService(
                "https://cloudapi.plasgate.com",
                "key",
                "secret",
                "Nham Health",
                "SMS Info",
                false,
                false);
        boolean sent = disabledService.sendSms("012345678", "Test verification code");
        assertThat(sent).isTrue();
    }

    @Test
    void fallsBackToConsoleWhenCredentialsMissingAndFallbackEnabled() {
        PlasgateSmsService fallbackService = new PlasgateSmsService(
                "https://cloudapi.plasgate.com",
                "",
                "",
                "Nham Health",
                "SMS Info",
                true,
                true);
        boolean sent = fallbackService.sendSms("012345678", "Test verification code");
        assertThat(sent).isTrue();
    }

    @Test
    void throwsWhenCredentialsMissingAndFallbackDisabled() {
        PlasgateSmsService strictService = new PlasgateSmsService(
                "https://cloudapi.plasgate.com",
                "",
                "",
                "Nham Health",
                "SMS Info",
                true,
                false);
        assertThatThrownBy(() -> strictService.sendSms("012345678", "Test verification code"))
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void fallsBackToConsoleWithoutCallingGatewayWhenSenderIsMissing() {
        PlasgateSmsService fallbackService = new PlasgateSmsService(
                "https://cloudapi.plasgate.com",
                "key",
                "secret",
                "",
                "",
                true,
                true);

        assertThat(fallbackService.sendSms("012345678", "Test verification code")).isTrue();
    }

    @Test
    void throwsWithoutCallingGatewayWhenSenderIsMissingAndFallbackDisabled() {
        PlasgateSmsService strictService = new PlasgateSmsService(
                "https://cloudapi.plasgate.com",
                "key",
                "secret",
                "",
                "",
                true,
                false);

        assertThatThrownBy(() -> strictService.sendSms("012345678", "Test verification code"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("PLASGATE_SENDER_ID");
    }
}
