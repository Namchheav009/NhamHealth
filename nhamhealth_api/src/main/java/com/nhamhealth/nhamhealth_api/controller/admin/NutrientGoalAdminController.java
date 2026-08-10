package com.nhamhealth.nhamhealth_api.controller.admin;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.nhamhealth.nhamhealth_api.entity.Nutrient;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.entity.UserNutrientGoal;
import com.nhamhealth.nhamhealth_api.repository.NutrientRepository;
import com.nhamhealth.nhamhealth_api.repository.UserNutrientGoalRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

@Controller
public class NutrientGoalAdminController {

    private final UserNutrientGoalRepository goalRepository;
    private final UserRepository userRepository;
    private final NutrientRepository nutrientRepository;

    public NutrientGoalAdminController(UserNutrientGoalRepository goalRepository,
            UserRepository userRepository, NutrientRepository nutrientRepository) {
        this.goalRepository = goalRepository;
        this.userRepository = userRepository;
        this.nutrientRepository = nutrientRepository;
    }

    @GetMapping("/admin/nutrient-goals")
    public String nutrientGoalsPage(Authentication authentication, Model model) {
        List<UserNutrientGoal> goals = goalRepository.findAllByOrderByEffectiveFromDesc();
        LocalDate today = LocalDate.now();
        long activeGoals = goals.stream().filter(goal -> Boolean.TRUE.equals(goal.getIsActive())).count();
        long currentGoals = goals.stream().filter(goal -> Boolean.TRUE.equals(goal.getIsActive())
                && !goal.getEffectiveFrom().isAfter(today)
                && (goal.getEffectiveTo() == null || !goal.getEffectiveTo().isBefore(today))).count();
        long trackedNutrients = goals.stream().map(UserNutrientGoal::getNutrient)
                .filter(Objects::nonNull).map(Nutrient::getNutrientId).distinct().count();
        long usersWithGoals = goals.stream().map(UserNutrientGoal::getUser)
                .filter(Objects::nonNull).map(User::getUserId).distinct().count();

        List<User> users = userRepository.findAll().stream()
                .sorted(Comparator.comparing(User::getName, String.CASE_INSENSITIVE_ORDER)).toList();
        List<Nutrient> nutrients = nutrientRepository.findAllByOrderByDisplayOrderAsc().stream()
                .filter(nutrient -> Boolean.TRUE.equals(nutrient.getIsActive())).toList();

        model.addAttribute("pageTitle", "Nutrient Goals");
        model.addAttribute("activePage", "nutrient-goals");
        model.addAttribute("adminName", authentication.getName());
        model.addAttribute("nutrientGoals", goals);
        model.addAttribute("users", users);
        model.addAttribute("nutrients", nutrients);
        model.addAttribute("totalGoals", goals.size());
        model.addAttribute("activeGoals", activeGoals);
        model.addAttribute("currentGoals", currentGoals);
        model.addAttribute("trackedNutrients", trackedNutrients);
        model.addAttribute("usersWithGoals", usersWithGoals);
        return "admin/nutrient-goal";
    }

    @PostMapping("/admin/nutrient-goals")
    public String createGoal(@RequestParam Integer userId, @RequestParam Integer nutrientId,
            @RequestParam BigDecimal goalAmount, @RequestParam LocalDate effectiveFrom,
            @RequestParam(required = false) LocalDate effectiveTo,
            @RequestParam(defaultValue = "true") Boolean active, RedirectAttributes redirectAttributes) {
        if (goalAmount.signum() <= 0 || (effectiveTo != null && effectiveTo.isBefore(effectiveFrom))) {
            redirectAttributes.addFlashAttribute("errorMessage", "Enter a positive goal and a valid date range.");
            return "redirect:/admin/nutrient-goals";
        }
        UserNutrientGoal goal = new UserNutrientGoal();
        goal.setUser(userRepository.findById(userId).orElseThrow());
        goal.setNutrient(nutrientRepository.findById(nutrientId).orElseThrow());
        goal.setGoalAmount(goalAmount);
        goal.setEffectiveFrom(effectiveFrom);
        goal.setEffectiveTo(effectiveTo);
        goal.setIsActive(active);
        goal.setCreatedAt(LocalDateTime.now());
        goal.setUpdatedAt(LocalDateTime.now());
        goalRepository.save(goal);
        redirectAttributes.addFlashAttribute("successMessage", "Nutrient goal added successfully.");
        return "redirect:/admin/nutrient-goals";
    }

    @DeleteMapping("/admin/nutrient-goals/{goalId}")
    public ResponseEntity<Void> deleteGoal(@PathVariable Integer goalId) {
        if (!goalRepository.existsById(goalId)) return ResponseEntity.notFound().build();
        goalRepository.deleteById(goalId);
        return ResponseEntity.noContent().build();
    }
}
