package com.nhamhealth.nhamhealth_api.repository;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import com.nhamhealth.nhamhealth_api.entity.Follow;

@Repository
public interface FollowRepository extends JpaRepository<Follow, Integer> {
    List<Follow> findAllByOrderByRequestedAtDesc();

    boolean existsByFollowerUserUserIdAndFollowingUserUserId(Integer followerId, Integer followingId);

    List<Follow> findByFollowerUserUserId(Integer followerId);
    List<Follow> findByFollowingUserUserId(Integer followingId);
    java.util.Optional<Follow> findByFollowerUserUserIdAndFollowingUserUserId(Integer followerId, Integer followingId);

    long countByRequestedAtGreaterThanEqual(LocalDateTime since);

    @Query("select count(follow) from Follow follow where lower(follow.status) = 'active' and exists "
            + "(select reciprocal.followId from Follow reciprocal where reciprocal.followerUser = follow.followingUser "
            + "and reciprocal.followingUser = follow.followerUser and lower(reciprocal.status) = 'active')")
    long countMutualDirections();
}
