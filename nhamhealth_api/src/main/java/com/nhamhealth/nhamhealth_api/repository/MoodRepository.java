package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.Mood;

public interface MoodRepository extends JpaRepository<Mood, Integer> {
    List<Mood> findAllByOrderByMoodNameAsc();
}
