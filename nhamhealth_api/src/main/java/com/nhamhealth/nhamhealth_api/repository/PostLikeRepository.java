package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import com.nhamhealth.nhamhealth_api.entity.PostLike;

public interface PostLikeRepository extends JpaRepository<PostLike, Integer> {
    @org.springframework.data.jpa.repository.EntityGraph(attributePaths = {"user", "post"})
    List<PostLike> findAllByOrderByCreatedAtDesc();

    long countByPostPostId(Integer postId);
    boolean existsByUserUserIdAndPostPostId(Integer userId, Integer postId);
    Optional<PostLike> findByUserUserIdAndPostPostId(Integer userId, Integer postId);
}
