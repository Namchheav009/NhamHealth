package com.nhamhealth.nhamhealth_api.repository.community;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.nhamhealth.nhamhealth_api.entity.Follow;
import jakarta.persistence.LockModeType;

@Repository
public interface FollowRepository extends JpaRepository<Follow, Integer> {
    @EntityGraph(attributePaths = { "followerUser", "followingUser" })
    List<Follow> findAllByOrderByRequestedAtDesc();

    @EntityGraph(attributePaths = { "followerUser", "followingUser" })
    @Query("select follow from Follow follow where upper(follow.status) in ('ACTIVE', 'BLOCKED') "
            + "order by follow.requestedAt desc")
    List<Follow> findVisibleAdminFollows();

    boolean existsByFollowerUserUserIdAndFollowingUserUserId(Integer followerId, Integer followingId);
    boolean existsByFollowerUserUserIdAndFollowingUserUserIdAndStatusIgnoreCase(
            Integer followerId, Integer followingId, String status);

    List<Follow> findByFollowerUserUserId(Integer followerId);
    List<Follow> findByFollowingUserUserId(Integer followingId);
    @EntityGraph(attributePaths = { "followerUser", "followingUser" })
    List<Follow> findByStatusIgnoreCase(String status);
    Optional<Follow> findFirstByFollowerUserUserIdAndFollowingUserUserIdAndStatusIgnoreCaseOrderByFollowIdAsc(
            Integer followerId, Integer followingId, String status);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @EntityGraph(attributePaths = { "followerUser", "followingUser" })
    @Query("select follow from Follow follow where upper(follow.status) = 'FOLLOW_PENDING' and "
            + "((follow.followerUser.userId = :firstId and follow.followingUser.userId = :secondId) or "
            + "(follow.followerUser.userId = :secondId and follow.followingUser.userId = :firstId))")
    Optional<Follow> findPendingFriendBetweenForUpdate(
            @Param("firstId") Integer firstId, @Param("secondId") Integer secondId);

    @EntityGraph(attributePaths = { "followerUser", "followingUser" })
    @Query("select follow from Follow follow where upper(follow.status) = 'FOLLOW_PENDING' and "
            + "(follow.followerUser.userId = :userId or follow.followingUser.userId = :userId)")
    List<Follow> findPendingFriendForUser(@Param("userId") Integer userId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @EntityGraph(attributePaths = { "followerUser", "followingUser" })
    @Query("select follow from Follow follow where follow.followId = :followId")
    Optional<Follow> findByIdForUpdate(@Param("followId") Integer followId);

    @Query("select count(follow) > 0 from Follow follow where "
            + "upper(follow.status) = 'BLOCKED' and "
            + "((follow.followerUser.userId = :firstId and follow.followingUser.userId = :secondId) or "
            + "(follow.followerUser.userId = :secondId and follow.followingUser.userId = :firstId))")
    boolean existsBlockedBetween(Integer firstId, Integer secondId);

    long countByRequestedAtGreaterThanEqual(LocalDateTime since);
    @Query("select count(follow) from Follow follow where upper(follow.status) = 'ACTIVE' "
            + "and follow.requestedAt >= :since")
    long countActiveByRequestedAtGreaterThanEqual(@Param("since") LocalDateTime since);
    long countByFollowingUserUserIdAndStatusIgnoreCase(Integer userId, String status);
    long countByFollowerUserUserIdAndStatusIgnoreCase(Integer userId, String status);

    @Query("select count(follow) from Follow follow where lower(follow.status) = 'active' and exists "
            + "(select reciprocal.followId from Follow reciprocal where reciprocal.followerUser = follow.followingUser "
            + "and reciprocal.followingUser = follow.followerUser and lower(reciprocal.status) = 'active')")
    long countMutualDirections();
}
