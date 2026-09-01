package com.nhamhealth.nhamhealth_api.repository.catalog;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.cache.annotation.Cacheable;

import com.nhamhealth.nhamhealth_api.entity.TagType;

public interface TagTypeRepository extends JpaRepository<TagType, Integer> {

    @Cacheable("tags")
    List<TagType> findAllByOrderByTagNameAsc();

    Optional<TagType> findByTagNameIgnoreCase(String tagName);
}
