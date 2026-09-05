package com.nhamhealth.nhamhealth_api.repository.auth;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.VerificationCode;

public interface VerificationCodeRepository extends JpaRepository<VerificationCode, Integer> {

    Optional<VerificationCode> findFirstByDestinationIgnoreCaseAndPurposeOrderByCreatedAtDesc(
            String destination,
            String purpose);

    List<VerificationCode> findByDestinationIgnoreCaseAndPurposeAndStatus(
            String destination,
            String purpose,
            String status);

    List<VerificationCode> findByUserAndPurposeAndStatus(
            com.nhamhealth.nhamhealth_api.entity.User user,
            String purpose,
            String status);
}
