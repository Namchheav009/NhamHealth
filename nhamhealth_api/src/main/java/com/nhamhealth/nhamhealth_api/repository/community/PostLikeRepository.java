package com.nhamhealth.nhamhealth_api.repository.community;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.nhamhealth.nhamhealth_api.entity.PostLike;

public interface PostLikeRepository extends JpaRepository<PostLike, Integer> {

    @org.springframework.data.jpa.repository.EntityGraph(attributePaths = {"user", "post"})
    List<PostLike> findAllByOrderByCreatedAtDesc();

    long countByPostPostId(Integer postId);

    @Query("""
            select postLike.post.postId as postId, count(postLike) as total
            from PostLike postLike
            where postLike.post.postId in :postIds
            group by postLike.post.postId
            """)
    List<PostCount> countByPostIds(@Param("postIds") List<Integer> postIds);

    boolean existsByUserUserIdAndPostPostId(Integer userId, Integer postId);

    Optional<PostLike> findByUserUserIdAndPostPostId(Integer userId, Integer postId);

    // Keep the post and its lazy recipe attached while toggleLike builds its response.
    @org.springframework.data.jpa.repository.Modifying
    @Query("delete from PostLike p where p.user.userId = :userId and p.post.postId = :postId")
    int deleteByUserUserIdAndPostPostId(@Param("userId") Integer userId, @Param("postId") Integer postId);

    @org.springframework.data.jpa.repository.Modifying
    @Query(value = """
            insert into public.post_likes (user_id, user_meal_post_id, created_at)
            values (:userId, :postId, :createdAt)
            on conflict (user_id, user_meal_post_id) do nothing
            """, nativeQuery = true)
    int insertIgnoreConflict(
            @Param("userId") Integer userId,
            @Param("postId") Integer postId,
            @Param("createdAt") java.time.LocalDateTime createdAt);

    @org.springframework.data.jpa.repository.EntityGraph(attributePaths = {"user"})
    List<PostLike> findByPostPostIdOrderByCreatedAtDesc(Integer postId);

    interface PostCount {

        Integer getPostId();

        long getTotal();
    }
}
