package com.nhamhealth.nhamhealth_api.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

@Configuration
@Profile("dev")
public class DevSecurityConfig {
    // Development uses the same access-control rules as every other profile.
    // Development-only data loading is configured separately and must not weaken security.
}
