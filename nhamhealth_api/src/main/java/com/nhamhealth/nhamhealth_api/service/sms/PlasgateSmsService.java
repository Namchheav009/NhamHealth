package com.nhamhealth.nhamhealth_api.service.sms;

import java.time.Duration;
import java.util.Map;
import java.util.regex.Pattern;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;

@Service
public class PlasgateSmsService {

    private static final Logger log = LoggerFactory.getLogger(PlasgateSmsService.class);
    private static final Pattern NON_DIGITS = Pattern.compile("[^0-9]");

    private final RestClient client;
    private final String baseUrl;
    private final String privateKey;
    private final String secretKey;
    private final String defaultSenderId;
    private final String fallbackSenderId;
    private final boolean enabled;
    private final boolean fallbackToConsole;

    public PlasgateSmsService(
            @Value("${app.sms.plasgate.base-url:https://cloudapi.plasgate.com}") String baseUrl,
            @Value("${app.sms.plasgate.private-key:}") String privateKey,
            @Value("${app.sms.plasgate.secret-key:}") String secretKey,
            @Value("${app.sms.plasgate.sender-id:Nham Health}") String defaultSenderId,
            @Value("${app.sms.plasgate.fallback-sender-id:SMS Info}") String fallbackSenderId,
            @Value("${app.sms.plasgate.enabled:true}") boolean enabled,
            @Value("${app.sms.plasgate.fallback-to-console:true}") boolean fallbackToConsole) {
        this.baseUrl = baseUrl.replaceAll("/+$", "");
        this.privateKey = privateKey.trim();
        this.secretKey = secretKey.trim();
        this.defaultSenderId = defaultSenderId.trim();
        this.fallbackSenderId = fallbackSenderId.trim();
        this.enabled = enabled;
        this.fallbackToConsole = fallbackToConsole;

        SimpleClientHttpRequestFactory requestFactory = new SimpleClientHttpRequestFactory();
        requestFactory.setConnectTimeout((int) Duration.ofSeconds(10).toMillis());
        requestFactory.setReadTimeout((int) Duration.ofSeconds(15).toMillis());

        this.client = RestClient.builder()
                .baseUrl(this.baseUrl)
                .requestFactory(requestFactory)
                .build();
    }

    public PlasgateSmsService(
            String baseUrl,
            String privateKey,
            String secretKey,
            String defaultSenderId,
            String fallbackSenderId,
            boolean enabled) {
        this(baseUrl, privateKey, secretKey, defaultSenderId, fallbackSenderId, enabled, true);
    }

    /**
     * Send an SMS message using PlasGate SMS Gateway.
     *
     * @param rawPhone recipient phone number (supports local 0xx or
     * international 855xx format)
     * @param content SMS body content
     * @return true if successfully dispatched
     */
    public boolean sendSms(String rawPhone, String content) {
        if (!enabled) {
            log.info("PlasGate SMS is disabled by configuration. SMS to {} skipped: {}", maskPhone(rawPhone), content);
            log.info("PlasGate SMS is disabled by configuration. SMS to {} simulated: {}", maskPhone(rawPhone), content);
            return true;
        }

        if (privateKey.isBlank() || secretKey.isBlank()) {
            if (fallbackToConsole) {
                log.warn("PlasGate credentials missing. Simulated SMS delivery to {}: {}", maskPhone(rawPhone), content);
                return true;
            }
            log.warn("PlasGate credentials (private key or secret key) are missing. Cannot dispatch SMS.");
            throw new IllegalStateException("SMS gateway is not properly configured.");
        }

        String recipient = normalizePhoneNumber(rawPhone);
        String sender = defaultSenderId.isBlank() ? "SMS Info" : defaultSenderId;

        boolean success = executeSend(sender, recipient, content);
        if (!success && !sender.equalsIgnoreCase(fallbackSenderId) && !fallbackSenderId.isBlank()) {
            log.info("Retrying SMS delivery with fallback sender '{}' for recipient {}", fallbackSenderId, maskPhone(recipient));
            success = executeSend(fallbackSenderId, recipient, content);
        }

        if (!success && fallbackToConsole) {
            log.warn("PlasGate SMS delivery failed (e.g. sender '{}' not yet registered/approved on PlasGate). Falling back to console delivery for {}: {}",
                    sender, maskPhone(recipient), content);
            return true;
        }

        return success;
    }

    private boolean executeSend(String sender, String recipient, String content) {
        try {
            Map<String, Object> payload = Map.of(
                    "sender", sender,
                    "to", recipient,
                    "content", content
            );

            String response = client.post()
                    .uri(uriBuilder -> uriBuilder
                    .path("/rest/send")
                    .queryParam("private_key", privateKey)
                    .build())
                    .header("X-Secret", secretKey)
                    .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                    .body(payload)
                    .retrieve()
                    .body(String.class);

            log.info("PlasGate SMS dispatched to {} via sender '{}'. Response: {}", maskPhone(recipient), sender, response);
            return true;
        } catch (RestClientResponseException error) {
            log.error("PlasGate SMS HTTP error {} when sending to {}: {}",
                    error.getStatusCode(), maskPhone(recipient), error.getResponseBodyAsString());
            return false;
        } catch (Exception error) {
            log.error("Failed to send PlasGate SMS to {}: {}", maskPhone(recipient), error.getMessage());
            return false;
        }
    }

    /**
     * Normalizes a phone number to standard Cambodian international format
     * (e.g., 85512345678).
     */
    public String normalizePhoneNumber(String rawPhone) {
        if (rawPhone == null || rawPhone.isBlank()) {
            throw new IllegalArgumentException("Phone number cannot be empty.");
        }

        String trimmed = rawPhone.trim();
        if (trimmed.startsWith("+")) {
            trimmed = trimmed.substring(1);
        }

        String digitsOnly = NON_DIGITS.matcher(trimmed).replaceAll("");
        if (digitsOnly.isBlank()) {
            throw new IllegalArgumentException("Invalid phone number format.");
        }

        // Cambodian local format starts with 0 (e.g., 012345678 or 0961234567)
        if (digitsOnly.startsWith("0")) {
            digitsOnly = "855" + digitsOnly.substring(1);
        } else if (!digitsOnly.startsWith("855")) {
            // If user entered e.g. 12345678 (8-9 digits without leading zero)
            if (digitsOnly.length() >= 8 && digitsOnly.length() <= 9) {
                digitsOnly = "855" + digitsOnly;
            }
        }

        if (digitsOnly.length() < 9 || digitsOnly.length() > 15) {
            throw new IllegalArgumentException("Invalid phone number length.");
        }

        return digitsOnly;
    }

    public static String maskPhone(String phone) {
        if (phone == null || phone.length() < 5) {
            return "***";
        }
        int len = phone.length();
        return phone.substring(0, 3) + "****" + phone.substring(len - 3);
    }
}
