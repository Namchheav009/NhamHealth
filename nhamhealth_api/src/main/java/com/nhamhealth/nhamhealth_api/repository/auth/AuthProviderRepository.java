package com.nhamhealth.nhamhealth_api.repository.auth;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.AuthProvider;

public interface AuthProviderRepository extends JpaRepository<AuthProvider, Integer> {

    Optional<AuthProvider> findByProviderNameIgnoreCase(String providerName);
}
