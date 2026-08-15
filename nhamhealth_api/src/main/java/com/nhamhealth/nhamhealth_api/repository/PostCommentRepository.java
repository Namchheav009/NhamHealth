package com.nhamhealth.nhamhealth_api.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.PostComment;

public interface PostCommentRepository extends JpaRepository<PostComment, Integer> {
    long countByPostPostId(Integer postId);
}
