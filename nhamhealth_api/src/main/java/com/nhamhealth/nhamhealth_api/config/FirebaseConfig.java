package com.nhamhealth.nhamhealth_api.config;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;

@Configuration
public class FirebaseConfig {
    private static final Logger log = LoggerFactory.getLogger(FirebaseConfig.class);

    @Value("${nhamhealth.push.service-account-path:}")
    private String serviceAccountPath;

    @Bean
    @ConditionalOnProperty(name = "nhamhealth.push.enabled", havingValue = "true")
    FirebaseMessaging firebaseMessaging() throws IOException {
        if (FirebaseApp.getApps().isEmpty()) {
            GoogleCredentials credentials;
            if (serviceAccountPath != null && !serviceAccountPath.isBlank()) {
                File file = new File(serviceAccountPath);
                if (file.exists()) {
                    try (InputStream stream = new FileInputStream(file)) {
                        credentials = GoogleCredentials.fromStream(stream);
                    }
                } else {
                    log.warn("Firebase service account file not found at {}. Falling back to default credentials.",
                            serviceAccountPath);
                    credentials = GoogleCredentials.getApplicationDefault();
                }
            } else {
                credentials = GoogleCredentials.getApplicationDefault();
            }

            var options = FirebaseOptions.builder()
                    .setCredentials(credentials)
                    .build();
            FirebaseApp.initializeApp(options);
            log.info("Firebase Cloud Messaging initialized");
        }
        return FirebaseMessaging.getInstance();
    }
}
