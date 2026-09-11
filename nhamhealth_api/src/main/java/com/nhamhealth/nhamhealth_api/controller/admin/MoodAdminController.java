package com.nhamhealth.nhamhealth_api.controller.admin;

import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

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
import com.nhamhealth.nhamhealth_api.entity.MoodTranslation;
import com.nhamhealth.nhamhealth_api.repository.translation.MoodTranslationRepository;
import com.nhamhealth.nhamhealth_api.repository.wellness.MoodRepository;
import com.nhamhealth.nhamhealth_api.service.wellness.MoodAdminService;

import jakarta.validation.Valid;

@Controller
public class MoodAdminController {

    private final MoodRepository moodRepository;
    private final MoodTranslationRepository moodTranslationRepository;
    private final MoodAdminService moodAdminService;

    public MoodAdminController(
            MoodRepository moodRepository,
            MoodTranslationRepository moodTranslationRepository,
            MoodAdminService moodAdminService) {
        this.moodRepository = moodRepository;
        this.moodTranslationRepository = moodTranslationRepository;
        this.moodAdminService = moodAdminService;
    }

    @GetMapping("/admin/moods")
    public String moods(Model model) {
        List<Mood> moods = moodRepository.findAllByOrderByMoodNameAsc();
        int total = moods.size();
        long active = moods.stream().filter(mood -> Boolean.TRUE.equals(mood.getIsActive())).count();

        Map<Integer, MoodTranslation> kmTranslations = moodTranslationRepository
                .findByLanguageCode("km")
                .stream()
                .collect(Collectors.toMap(t -> t.getMood().getMoodId(), Function.identity(), (a, b) -> a));

        model.addAttribute("pageTitle", "Moods");
        model.addAttribute("moods", moods);
        model.addAttribute("kmTranslations", kmTranslations);
        model.addAttribute("totalMoods", total);
        model.addAttribute("activeMoods", active);
        model.addAttribute("inactiveMoods", total - active);

        return "admin/moods";
    }

    @PostMapping("/admin/moods")
    @ResponseBody
    public ResponseEntity<?> createMood(@Valid @RequestBody AdminMoodRequest request) {
        try {
            return ResponseEntity.ok(moodAdminService.create(request));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(Map.of("message", exception.getMessage()));
        }
    }

    @PutMapping("/admin/moods/{moodId}")
    @ResponseBody
    public ResponseEntity<?> updateMood(@PathVariable Integer moodId, @Valid @RequestBody AdminMoodRequest request) {
        try {
            return ResponseEntity.ok(moodAdminService.update(moodId, request));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(Map.of("message", exception.getMessage()));
        }
    }

    @DeleteMapping("/admin/moods/{moodId}")
    @ResponseBody
    public ResponseEntity<?> deleteMood(@PathVariable Integer moodId) {
        try {
            moodAdminService.delete(moodId);
            return ResponseEntity.noContent().build();
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.notFound().build();
        } catch (IllegalStateException exception) {
            return ResponseEntity.status(409).body(Map.of("message", exception.getMessage()));
        }
    }
}
