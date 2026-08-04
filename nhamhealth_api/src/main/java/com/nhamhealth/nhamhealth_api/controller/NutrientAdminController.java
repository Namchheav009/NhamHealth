package com.nhamhealth.nhamhealth_api.controller;

import java.util.List;

import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import com.nhamhealth.nhamhealth_api.entity.Nutrient;
import com.nhamhealth.nhamhealth_api.repository.NutrientRepository;

@Controller
public class NutrientAdminController {

    private final NutrientRepository nutrientRepository;

    public NutrientAdminController(NutrientRepository nutrientRepository) {
        this.nutrientRepository = nutrientRepository;
    }

    @GetMapping("/admin/nutrients")
    public String nutrients(Authentication authentication, Model model) {
        List<Nutrient> nutrients = nutrientRepository.findAllByOrderByDisplayOrderAsc();

        long activeNutrients = nutrients.stream()
                .filter(nutrient -> Boolean.TRUE.equals(nutrient.getIsActive()))
                .count();
        double totalNutrients = nutrients.size();
        double activePercentage = totalNutrients > 0 ? (activeNutrients * 100.0) / totalNutrients : 0.0;

        model.addAttribute("pageTitle", "Nutrients");
        model.addAttribute("activePage", "nutrients");
        model.addAttribute("adminName", authentication.getName());
        model.addAttribute("nutrients", nutrients);
        model.addAttribute("totalNutrients", (int) totalNutrients);
        model.addAttribute("activeNutrients", activeNutrients);
        model.addAttribute("inactiveNutrients", Math.max(0, nutrients.size() - activeNutrients));
        model.addAttribute("activePercentage", activePercentage);
        return "admin/nutrients";
    }
}
