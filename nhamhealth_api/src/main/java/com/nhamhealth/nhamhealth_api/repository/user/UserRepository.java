package com.nhamhealth.nhamhealth_api.repository.user;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.User;

public interface UserRepository extends JpaRepository<User, Integer> {

    @EntityGraph(attributePaths = "role")
    Optional<User> findByEmailIgnoreCase(String email);

    @EntityGraph(attributePaths = "role")
    Optional<User> findByPhoneNumber(String phoneNumber);

    @EntityGraph(attributePaths = "role")
    Optional<User> findByEmailIgnoreCaseOrPhoneNumber(String email, String phoneNumber);

    long countByIsVerifiedTrue();

    long countByStatusNot(String status);

    long countByIsVerifiedTrueAndStatusNot(String status);

    long countByCreatedAtGreaterThanEqualAndCreatedAtLessThan(LocalDateTime start, LocalDateTime end);

    long countByCreatedAtGreaterThanEqualAndCreatedAtLessThanAndStatusNot(
            LocalDateTime start, LocalDateTime end, String status);

    List<User> findTop5ByOrderByCreatedAtDesc();

    List<User> findTop5ByStatusNotOrderByCreatedAtDesc(String status);
}
