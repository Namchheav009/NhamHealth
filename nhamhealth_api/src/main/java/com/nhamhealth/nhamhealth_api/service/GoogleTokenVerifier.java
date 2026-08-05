package com.nhamhealth.nhamhealth_api.service;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.List;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;

@Service
public class GoogleTokenVerifier {

    private final GoogleIdTokenVerifier verifier;
    private final boolean configured;

    public GoogleTokenVerifier(
            @Value("${app.auth.google.client-id:}") String clientId) {
        this.configured = clientId != null && !clientId.isBlank();
        this.verifier = configured
                ? new GoogleIdTokenVerifier.Builder(
                        new NetHttpTransport(), GsonFactory.getDefaultInstance())
                        .setAudience(List.of(clientId.trim()))
                        .build()
                : null;
    }

    public GoogleIdentity verify(String idToken) {
        if (!configured) {
            throw new IllegalStateException(
                    "Google sign-in is not configured on the server");
        }

        try {
            GoogleIdToken verifiedToken = verifier.verify(idToken);
            if (verifiedToken == null) {
                throw new IllegalArgumentException("Invalid Google ID token");
            }

            GoogleIdToken.Payload payload = verifiedToken.getPayload();
            if (!Boolean.TRUE.equals(payload.getEmailVerified())
                    || payload.getEmail() == null
                    || payload.getEmail().isBlank()) {
                throw new IllegalArgumentException(
                        "The Google account email is not verified");
            }

            return new GoogleIdentity(
                    payload.getSubject(),
                    payload.getEmail(),
                    (String) payload.get("name"),
                    (String) payload.get("picture"));
        } catch (GeneralSecurityException | IOException exception) {
            throw new IllegalArgumentException(
                    "Could not verify the Google ID token", exception);
        }
    }

    public record GoogleIdentity(
            String subject,
            String email,
            String name,
            String pictureUrl) {
    }
}
