package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.TagType;

public interface TagTypeRepository extends JpaRepository<TagType, Integer> {

    List<TagType> findAllByOrderByTagNameAsc();

    Optional<TagType> findByTagNameIgnoreCase(String tagName);
}
