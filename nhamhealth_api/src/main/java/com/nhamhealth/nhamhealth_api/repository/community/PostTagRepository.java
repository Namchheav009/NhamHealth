package com.nhamhealth.nhamhealth_api.repository.community;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.PostTag;

public interface PostTagRepository extends JpaRepository<PostTag, Integer> {

    List<PostTag> findByPostPostIdOrderByPostTagId(Integer postId);

    void deleteByPostPostId(Integer postId);
}
