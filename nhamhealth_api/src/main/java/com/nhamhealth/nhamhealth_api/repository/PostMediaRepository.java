package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import com.nhamhealth.nhamhealth_api.entity.PostMedia;

public interface PostMediaRepository extends JpaRepository<PostMedia, Integer> {
    List<PostMedia> findByPostPostIdOrderByDisplayOrder(Integer postId);
}
