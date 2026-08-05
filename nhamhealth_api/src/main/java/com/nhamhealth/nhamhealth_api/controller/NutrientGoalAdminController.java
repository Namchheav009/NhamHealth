package com.nhamhealth.nhamhealth_api.controller;

import java.util.List;
import java.util.Objects;

import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import com.nhamhealth.nhamhealth_api.entity.UserNutrientGoal;
import com.nhamhealth.nhamhealth_api.repository.UserNutrientGoalRepository;

@Controller
public class NutrientGoalAdminController {

    private final UserNutrientGoalRepository userNutrientGoalRepository;

    public NutrientGoalAdminController(UserNutrientGoalRepository userNutrientGoalRepository) {
        this.userNutrientGoalRepository = userNutrientGoalRepository;
    }

    @GetMapping("/admin/nutrient-goals")
    public String nutrientGoalsPage(Authentication authentication, Model model) {
        List<UserNutrientGoal> goals = userNutrientGoalRepository.findByIsActiveTrueOrderByEffectiveFromDesc();
        long trackedNutrients = goals.stream()
                .map(goal -> goal.getNutrient() != null ? goal.getNutrient().getNutrientName() : null)
                .filter(Objects::nonNull)
                .distinct()
                .count();

        model.addAttribute("pageTitle", "Nutrient Goals");
        model.addAttribute("activePage", "nutrient-goals");
        model.addAttribute("adminName", authentication.getName());
        model.addAttribute("nutrientGoals", goals);
        model.addAttribute("totalGoals", goals.size());
        model.addAttribute("trackedNutrients", trackedNutrients);

        return "admin/nutrient-goal";
    }
}
