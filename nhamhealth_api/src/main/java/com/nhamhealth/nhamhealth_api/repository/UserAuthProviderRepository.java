package com.nhamhealth.nhamhealth_api.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.UserAuthProvider;

public interface UserAuthProviderRepository extends JpaRepository<UserAuthProvider, Integer> {

    Optional<UserAuthProvider> findByAuthProvider_ProviderNameIgnoreCaseAndProviderUserKey(
            String providerName,
            String providerUserKey);
}
