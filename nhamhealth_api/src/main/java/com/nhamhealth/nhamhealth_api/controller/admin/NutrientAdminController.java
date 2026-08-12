package com.nhamhealth.nhamhealth_api.controller.admin;

import java.util.List;
import java.util.Map;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseBody;

import jakarta.validation.Valid;

import com.nhamhealth.nhamhealth_api.dto.request.AdminNutrientRequest;
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

    @PostMapping("/admin/nutrients")
    @ResponseBody
    public ResponseEntity<?> createNutrient(@Valid @RequestBody AdminNutrientRequest request) {
        if (nutrientRepository.existsByNutrientNameIgnoreCase(request.nutrientName().trim())) {
            return ResponseEntity.badRequest().body(message("A nutrient with this name already exists."));
        }

        Nutrient nutrient = new Nutrient();
        applyRequest(nutrient, request);
        Nutrient savedNutrient = nutrientRepository.save(nutrient);
        return ResponseEntity.status(HttpStatus.CREATED).body(savedNutrient);
    }

    @PutMapping("/admin/nutrients/{nutrientId}")
    @ResponseBody
    public ResponseEntity<?> updateNutrient(
            @PathVariable Integer nutrientId,
            @Valid @RequestBody AdminNutrientRequest request) {
        Nutrient nutrient = nutrientRepository.findById(nutrientId).orElse(null);
        if (nutrient == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(message("Nutrient not found."));
        }
        if (nutrientRepository.existsByNutrientNameIgnoreCaseAndNutrientIdNot(
                request.nutrientName().trim(), nutrientId)) {
            return ResponseEntity.badRequest().body(message("A nutrient with this name already exists."));
        }

        applyRequest(nutrient, request);
        return ResponseEntity.ok(nutrientRepository.save(nutrient));
    }

    @DeleteMapping("/admin/nutrients/{nutrientId}")
    @ResponseBody
    @Transactional
    public ResponseEntity<?> deleteNutrient(@PathVariable Integer nutrientId) {
        Nutrient nutrient = nutrientRepository.findById(nutrientId).orElse(null);
        if (nutrient == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(message("Nutrient not found."));
        }

        try {
            nutrientRepository.delete(nutrient);
            nutrientRepository.flush();
            return ResponseEntity.noContent().build();
        } catch (DataIntegrityViolationException exception) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(message("This nutrient is already in use and cannot be deleted."));
        }
    }

    private void applyRequest(Nutrient nutrient, AdminNutrientRequest request) {
        nutrient.setNutrientName(request.nutrientName().trim());
        nutrient.setUnit(request.unit().trim());
        nutrient.setIsCore(request.core());
        nutrient.setIsActive(request.active());
        nutrient.setDisplayOrder(request.displayOrder());
    }

    private Map<String, String> message(String message) {
        return Map.of("message", message);
    }
}
