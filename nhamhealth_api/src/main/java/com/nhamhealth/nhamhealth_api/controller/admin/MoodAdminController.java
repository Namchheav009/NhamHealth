package com.nhamhealth.nhamhealth_api.controller.admin;

import java.util.List;
import java.util.Map;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseBody;

import com.nhamhealth.nhamhealth_api.dto.request.AdminMoodRequest;
import com.nhamhealth.nhamhealth_api.entity.Mood;
import com.nhamhealth.nhamhealth_api.repository.MoodRepository;

import jakarta.validation.Valid;

@Controller
public class MoodAdminController {

    private final MoodRepository moodRepository;

    public MoodAdminController(MoodRepository moodRepository) {
        this.moodRepository = moodRepository;
    }

    @GetMapping("/admin/moods")
    public String moods(Model model) {
        List<Mood> moods = moodRepository.findAllByOrderByMoodNameAsc();
        int total = moods.size();
        long active = moods.stream().filter(mood -> Boolean.TRUE.equals(mood.getIsActive())).count();

        model.addAttribute("pageTitle", "Moods");
        model.addAttribute("moods", moods);
        model.addAttribute("totalMoods", total);
        model.addAttribute("activeMoods", active);
        model.addAttribute("inactiveMoods", total - active);

        return "admin/moods";
    }

    @PostMapping("/admin/moods")
    @ResponseBody
    public ResponseEntity<?> createMood(@Valid @RequestBody AdminMoodRequest request) {
        if (moodRepository.findByMoodNameIgnoreCase(request.moodName().trim()).isPresent()) {
            return ResponseEntity.badRequest().body(Map.of("message", "A mood with this name already exists"));
        }
        Mood mood = new Mood();
        apply(mood, request);
        return ResponseEntity.ok(toResponse(moodRepository.saveAndFlush(mood)));
    }

    @PutMapping("/admin/moods/{moodId}")
    @ResponseBody
    public ResponseEntity<?> updateMood(@PathVariable Integer moodId, @Valid @RequestBody AdminMoodRequest request) {
        return moodRepository.findById(moodId)
                .<ResponseEntity<?>>map(mood -> {
                    boolean duplicate = moodRepository.findByMoodNameIgnoreCase(request.moodName().trim())
                            .filter(existing -> !existing.getMoodId().equals(moodId)).isPresent();
                    if (duplicate) {
                        return ResponseEntity.badRequest().body(Map.of("message", "A mood with this name already exists"));
                    }
                    apply(mood, request);
                    return ResponseEntity.ok(toResponse(moodRepository.saveAndFlush(mood)));
                })
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @DeleteMapping("/admin/moods/{moodId}")
    @ResponseBody
    public ResponseEntity<?> deleteMood(@PathVariable Integer moodId) {
        if (!moodRepository.existsById(moodId)) {
            return ResponseEntity.notFound().build();
        }
        try {
            moodRepository.deleteById(moodId);
            moodRepository.flush();
            return ResponseEntity.noContent().build();
        } catch (DataIntegrityViolationException exception) {
            return ResponseEntity.status(409).body(Map.of(
                    "message", "This mood is used by wellness or AI records. Mark it inactive instead."));
        }
    }

    private void apply(Mood mood, AdminMoodRequest request) {
        mood.setMoodName(request.moodName().trim());
        mood.setEmojiCode(request.emojiCode() == null || request.emojiCode().isBlank()
                ? null : request.emojiCode().trim());
        mood.setIsActive(request.active() == null || request.active());
    }

    private Map<String, Object> toResponse(Mood mood) {
        return Map.of(
                "id", mood.getMoodId(),
                "moodName", mood.getMoodName(),
                "emojiCode", mood.getEmojiCode() == null ? "" : mood.getEmojiCode(),
                "active", Boolean.TRUE.equals(mood.getIsActive()));
    }
}
