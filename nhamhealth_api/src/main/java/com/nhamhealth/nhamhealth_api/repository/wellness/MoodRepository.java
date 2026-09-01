package com.nhamhealth.nhamhealth_api.repository.wellness;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.Mood;

public interface MoodRepository extends JpaRepository<Mood, Integer> {
    List<Mood> findAllByOrderByMoodNameAsc();

    List<Mood> findAllByIsActiveTrueOrderByMoodNameAsc();

    Optional<Mood> findByMoodNameIgnoreCase(String moodName);
}
