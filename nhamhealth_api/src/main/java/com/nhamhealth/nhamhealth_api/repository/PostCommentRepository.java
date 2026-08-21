package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.nhamhealth.nhamhealth_api.entity.PostComment;

public interface PostCommentRepository extends JpaRepository<PostComment, Integer> {
    long countByPostPostId(Integer postId);

    @Query("""
            select comment.post.postId as postId, count(comment) as total
            from PostComment comment
            where comment.post.postId in :postIds
            group by comment.post.postId
            """)
    List<PostCount> countByPostIds(@Param("postIds") List<Integer> postIds);

    interface PostCount {
        Integer getPostId();
        long getTotal();
    }
}
