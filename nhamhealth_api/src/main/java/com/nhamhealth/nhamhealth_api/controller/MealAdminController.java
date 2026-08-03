package com.nhamhealth.nhamhealth_api.controller;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseBody;

import com.nhamhealth.nhamhealth_api.dto.MealAdminRowDto;
import com.nhamhealth.nhamhealth_api.service.MealAdminService;

@Controller
public class MealAdminController {

    private final MealAdminService mealAdminService;

    public MealAdminController(MealAdminService mealAdminService) {
        this.mealAdminService = mealAdminService;
    }

    @GetMapping("/admin/meals")
    public String mealsPage(Authentication authentication, Model model) {
        model.addAttribute("pageTitle", "Meals");
        model.addAttribute("activePage", "meals");
        model.addAttribute("adminName", authentication.getName());
        return "admin/meals";
    }

    @GetMapping("/api/v1/admin/meals")
    @ResponseBody
    public ResponseEntity<List<MealAdminRowDto>> listMeals() {
        return ResponseEntity.ok(mealAdminService.getMealsForAdmin());
    }

    @PostMapping("/api/v1/admin/meals")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> createMeal(@RequestBody Map<String, Object> payload) {
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Meal save endpoint is ready for wiring to the database service.");
        response.put("payload", payload);
        return ResponseEntity.ok(response);
    }
}
