package com.nhamhealth.nhamhealth_api.repository.community;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.CommentLike;

public interface CommentLikeRepository extends JpaRepository<CommentLike, Integer> {
    long countByPostCommentCommentId(Integer commentId);

    boolean existsByUserUserIdAndPostCommentCommentId(Integer userId, Integer commentId);

    Optional<CommentLike> findByUserUserIdAndPostCommentCommentId(Integer userId, Integer commentId);
}
