package com.nhamhealth.nhamhealth_api.repository.user;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.UserProfile;

public interface UserProfileRepository extends JpaRepository<UserProfile, Integer> {

    Optional<UserProfile> findByUser_UserId(Integer userId);

    Optional<UserProfile> findFirstByPhoneNumber(String phoneNumber);

    @EntityGraph(attributePaths = "user")
    List<UserProfile> findByUser_UserIdIn(Collection<Integer> userIds);
}
