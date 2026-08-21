package com.nhamhealth.nhamhealth_api.repository;

import java.util.Optional;
import java.util.Collection;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.EntityGraph;

import com.nhamhealth.nhamhealth_api.entity.UserProfile;

public interface UserProfileRepository extends JpaRepository<UserProfile, Integer> {

    Optional<UserProfile> findByUser_UserId(Integer userId);

    @EntityGraph(attributePaths = "user")
    List<UserProfile> findByUser_UserIdIn(Collection<Integer> userIds);
}
