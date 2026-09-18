package com.nhamhealth.nhamhealth_api.service.email;

import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import jakarta.mail.internet.MimeMessage;

/**
 * Service for sending transactional emails via Gmail SMTP or Brevo HTTP API v3.
 */
@Service
public class BrevoEmailService {

    private static final Logger LOGGER = LoggerFactory.getLogger(BrevoEmailService.class);

    private final RestClient restClient;
    private final String apiKey;
    private final String senderEmail;
    private final String senderName;
    private final JavaMailSender mailSender;

    public BrevoEmailService(
            @Value("${BREVO_API_KEY:}") String apiKey,
            @Value("${BREVO_SENDER_EMAIL:${app.mail.from:${spring.mail.username:no-reply@nhamhealth.local}}}") String senderEmail,
            @Value("${BREVO_SENDER_NAME:NhamHealth}") String senderName,
            ObjectProvider<JavaMailSender> mailSenderProvider) {

        this.apiKey = apiKey;
        this.senderEmail = senderEmail;
        this.senderName = senderName;
        this.mailSender = mailSenderProvider.getIfAvailable();

        this.restClient = RestClient.builder()
                .baseUrl("https://api.brevo.com/v3")
                .build();
    }

    public void sendEmail(
            String to,
            String subject,
            String plainText,
            String htmlContent) {

        // Try Gmail SMTP first for best deliverability and primary inbox placement
        if (mailSender != null) {
            try {
                sendWithSmtp(to, subject, plainText, htmlContent);
                LOGGER.info("Email successfully sent to {} via SMTP", to);
                return;
            } catch (Exception smtpEx) {
                LOGGER.warn("SMTP email delivery failed to {}: {}. Attempting Brevo API fallback...", to, smtpEx.getMessage());
                if (apiKey != null && !apiKey.isBlank()) {
                    try {
                        sendWithBrevo(to, subject, plainText, htmlContent);
                        LOGGER.info("Email successfully sent to {} via Brevo API fallback", to);
                        return;
                    } catch (Exception brevoEx) {
                        brevoEx.addSuppressed(smtpEx);
                        throw brevoEx;
                    }
                }
                throw (smtpEx instanceof RuntimeException re) ? re : new IllegalStateException(smtpEx);
            }
        }

        // If mailSender is not available, try Brevo API
        if (apiKey != null && !apiKey.isBlank()) {
            sendWithBrevo(to, subject, plainText, htmlContent);
            LOGGER.info("Email successfully sent to {} via Brevo API", to);
            return;
        }

        throw new IllegalStateException("Neither SMTP nor Brevo API is configured for sending email");
    }

    private void sendWithBrevo(String to, String subject, String plainText, String htmlContent) {
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

    private void sendWithSmtp(String to, String subject, String plainText, String htmlContent) {
        try {
            if (mailSender == null) {
                throw new IllegalStateException(
                        "Gmail SMTP is not configured; set GMAIL_USERNAME and GMAIL_APP_PASSWORD");
            }
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            String from = (senderEmail != null && !senderEmail.isBlank())
                    ? senderEmail : "no-reply@nhamhealth.local";
            helper.setFrom(from, senderName);
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(plainText, htmlContent);
            mailSender.send(message);
        } catch (Exception exception) {
            throw new IllegalStateException("Could not send transactional email through Gmail SMTP: " + exception.getMessage(), exception);
        }
    }
}
