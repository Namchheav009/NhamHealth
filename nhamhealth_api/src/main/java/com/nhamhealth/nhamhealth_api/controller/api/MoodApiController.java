package com.nhamhealth.nhamhealth_api.controller.api;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.nhamhealth.nhamhealth_api.dto.response.MoodResponse;
import com.nhamhealth.nhamhealth_api.repository.MoodRepository;

@RestController
@RequestMapping("/api/v1/moods")
public class MoodApiController {

    private final MoodRepository moodRepository;

    public MoodApiController(MoodRepository moodRepository) {
        this.moodRepository = moodRepository;
    }

    /**
     * Deliberately returns only active entries, so an admin can hide a mood from
     * the app without losing historical wellness records that reference it.
     */
    @GetMapping
    public ResponseEntity<List<MoodResponse>> activeMoods() {
        List<MoodResponse> moods = moodRepository.findAllByIsActiveTrueOrderByMoodNameAsc()
                .stream()
                .map(MoodResponse::from)
                .toList();
        return ResponseEntity.ok(moods);
    }
}
