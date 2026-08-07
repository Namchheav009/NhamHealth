package com.nhamhealth.nhamhealth_api.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.Post;

public interface PostRepository extends JpaRepository<Post, Integer> {
}
