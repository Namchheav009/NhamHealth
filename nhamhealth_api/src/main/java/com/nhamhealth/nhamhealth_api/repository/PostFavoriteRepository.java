package com.nhamhealth.nhamhealth_api.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.PostFavorite;

public interface PostFavoriteRepository extends JpaRepository<PostFavorite, Integer> {

    java.util.List<PostFavorite> findAllByOrderBySavedAtDesc();

    long countByPostPostId(Integer postId);

    boolean existsByUserUserIdAndPostPostId(Integer userId, Integer postId);

    boolean existsByUserUserIdAndPostPostIdAndPostFavoriteIdNot(Integer userId, Integer postId, Integer favoriteId);
}
