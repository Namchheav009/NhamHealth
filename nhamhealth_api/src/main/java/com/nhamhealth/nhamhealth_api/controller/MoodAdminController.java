package com.nhamhealth.nhamhealth_api.controller;

import java.util.List;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import com.nhamhealth.nhamhealth_api.entity.Mood;
import com.nhamhealth.nhamhealth_api.repository.MoodRepository;

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
        String topName = !moods.isEmpty() ? moods.get(0).getMoodName() : "";
        int topCount = 0; // placeholder until usage tracked

        model.addAttribute("pageTitle", "Moods");
        model.addAttribute("moods", moods);
        model.addAttribute("totalMoods", total);
        model.addAttribute("topMoodName", topName);
        model.addAttribute("topMoodCount", topCount);
        model.addAttribute("totalSelections", 0);

        return "admin/moods";
    }
}
