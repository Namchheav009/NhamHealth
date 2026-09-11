package com.nhamhealth.nhamhealth_api.service.email;

import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

@Service
public class BrevoEmailService {

    private final RestClient restClient;
    private final String apiKey;
    private final String senderEmail;
    private final String senderName;

    public BrevoEmailService(
            @Value("${BREVO_API_KEY:}") String apiKey,
            @Value("${BREVO_SENDER_EMAIL:}") String senderEmail,
            @Value("${BREVO_SENDER_NAME:NhamHealth}") String senderName) {

        this.apiKey = apiKey;
        this.senderEmail = senderEmail;
        this.senderName = senderName;

        this.restClient = RestClient.builder()
                .baseUrl("https://api.brevo.com/v3")
                .build();
    }

    public void sendEmail(
            String to,
            String subject,
            String plainText,
            String htmlContent) {

        Map<String, Object> payload = Map.of(
                "sender", Map.of(
                        "name", senderName,
                        "email", senderEmail),
                "to", List.of(
                        Map.of("email", to)),
                "subject", subject,
                "textContent", plainText,
                "htmlContent", htmlContent);

        restClient.post()
                .uri("/smtp/email")
                .header("api-key", apiKey)
                .contentType(MediaType.APPLICATION_JSON)
                .body(payload)
                .retrieve()
                .toBodilessEntity();
    }
}