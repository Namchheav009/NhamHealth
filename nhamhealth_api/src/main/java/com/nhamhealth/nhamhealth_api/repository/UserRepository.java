package com.nhamhealth.nhamhealth_api.repository;

import java.util.Optional;
import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.EntityGraph;

import com.nhamhealth.nhamhealth_api.entity.User;

public interface UserRepository extends JpaRepository<User, Integer> {

    @EntityGraph(attributePaths = "role")
    Optional<User> findByEmailIgnoreCase(String email);

    long countByIsVerifiedTrue();

    long countByCreatedAtGreaterThanEqualAndCreatedAtLessThan(LocalDateTime start, LocalDateTime end);

    List<User> findTop5ByOrderByCreatedAtDesc();
}
