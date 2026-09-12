package com.nhamhealth.nhamhealth_api.service.email;

import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import jakarta.mail.internet.MimeMessage;

/**
 * Service for sending transactional emails via the Brevo (Sendinblue) HTTP API
 * v3.
 */
@Service
public class BrevoEmailService {

        private final RestClient restClient;
        private final String apiKey;
        private final String senderEmail;
        private final String senderName;
        private final JavaMailSender mailSender;

        public BrevoEmailService(
                        @Value("${BREVO_API_KEY:}") String apiKey,
                        @Value("${BREVO_SENDER_EMAIL:}") String senderEmail,
                        @Value("${BREVO_SENDER_NAME:NhamHealth}") String senderName,
                        JavaMailSender mailSender) {

                this.apiKey = apiKey;
                this.senderEmail = senderEmail;
                this.senderName = senderName;
                this.mailSender = mailSender;

                this.restClient = RestClient.builder()
                                .baseUrl("https://api.brevo.com/v3")
                                .build();
        }

        public void sendEmail(
                        String to,
                        String subject,
                        String plainText,
                        String htmlContent) {

                if (apiKey == null || apiKey.isBlank() || senderEmail == null || senderEmail.isBlank()) {
                        sendWithSmtp(to, subject, plainText, htmlContent);
                        return;
                }

                Map<String, Object> payload = Map.of(
                                "sender", Map.of(
                                                "name", senderName,
                                                "email", senderEmail),
                                "to", List.of(
                                                Map.of("email", to)),
                                "subject", subject,
                                "textContent", plainText,
                                "htmlContent", htmlContent);

                try {
                        restClient.post()
                                        .uri("/smtp/email")
                                        .header("api-key", apiKey)
                                        .contentType(MediaType.APPLICATION_JSON)
                                        .body(payload)
                                        .retrieve()
                                        .toBodilessEntity();
                } catch (RuntimeException brevoFailure) {
                        try {
                                sendWithSmtp(to, subject, plainText, htmlContent);
                        } catch (RuntimeException smtpFailure) {
                                smtpFailure.addSuppressed(brevoFailure);
                                throw smtpFailure;
                        }
                }
        }

        private void sendWithSmtp(String to, String subject, String plainText, String htmlContent) {
                try {
                        MimeMessage message = mailSender.createMimeMessage();
                        MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
                        if (senderEmail != null && !senderEmail.isBlank()) {
                                helper.setFrom(senderEmail, senderName);
                        }
                        helper.setTo(to);
                        helper.setSubject(subject);
                        helper.setText(plainText, htmlContent);
                        mailSender.send(message);
                } catch (Exception exception) {
                        throw new IllegalStateException("Could not send transactional email through Gmail SMTP", exception);
                }
        }
}
