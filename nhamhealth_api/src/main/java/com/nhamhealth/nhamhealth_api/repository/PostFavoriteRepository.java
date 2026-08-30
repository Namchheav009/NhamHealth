package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.nhamhealth.nhamhealth_api.entity.PostFavorite;

public interface PostFavoriteRepository extends JpaRepository<PostFavorite, Integer> {

    java.util.List<PostFavorite> findAllByOrderBySavedAtDesc();

    long countByPostPostId(Integer postId);

    @Query("""
            select favorite.post.postId as postId, count(favorite) as total
            from PostFavorite favorite
            where favorite.post.postId in :postIds
            group by favorite.post.postId
            """)
    List<PostCount> countByPostIds(@Param("postIds") List<Integer> postIds);

    boolean existsByUserUserIdAndPostPostId(Integer userId, Integer postId);

    boolean existsByUserUserIdAndPostPostIdAndPostFavoriteIdNot(Integer userId, Integer postId, Integer favoriteId);

    interface PostCount {
        Integer getPostId();
        long getTotal();
    }
}
