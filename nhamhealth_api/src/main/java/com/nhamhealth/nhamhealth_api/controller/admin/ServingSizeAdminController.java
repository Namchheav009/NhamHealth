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

import com.nhamhealth.nhamhealth_api.dto.request.AdminServingSizeRequest;
import com.nhamhealth.nhamhealth_api.entity.ServingSize;
import com.nhamhealth.nhamhealth_api.repository.ServingSizeRepository;

import jakarta.validation.Valid;

@Controller
public class ServingSizeAdminController {

    private final ServingSizeRepository servingSizeRepository;

    public ServingSizeAdminController(ServingSizeRepository servingSizeRepository) {
        this.servingSizeRepository = servingSizeRepository;
    }

    @GetMapping("/admin/serving-sizes")
    public String servingSizes(Model model) {
        List<ServingSize> servingSizes = servingSizeRepository.findAllByOrderByServingSizeNameAsc();
        int total = servingSizes.size();
        long active = servingSizes.stream().filter(s -> Boolean.TRUE.equals(s.getIsActive())).count();
        long inactive = total - active;

        model.addAttribute("pageTitle", "Serving Sizes");
        model.addAttribute("servingSizes", servingSizes);
        model.addAttribute("totalServingSizes", total);
        model.addAttribute("activeServingSizes", active);
        model.addAttribute("inactiveServingSizes", inactive);
        return "admin/serving-size";
    }

    @PostMapping("/admin/serving-sizes")
    @ResponseBody
    public ResponseEntity<?> createServingSize(@Valid @RequestBody AdminServingSizeRequest request) {
        if (servingSizeRepository.findByServingSizeNameIgnoreCase(request.servingSizeName().trim()).isPresent()) {
            return ResponseEntity.badRequest().body(Map.of("message", "A serving size with this name already exists"));
        }
        ServingSize servingSize = new ServingSize();
        apply(servingSize, request);
        return ResponseEntity.ok(toResponse(servingSizeRepository.saveAndFlush(servingSize)));
    }

    @PutMapping("/admin/serving-sizes/{servingSizeId}")
    @ResponseBody
    public ResponseEntity<?> updateServingSize(
            @PathVariable Integer servingSizeId,
            @Valid @RequestBody AdminServingSizeRequest request) {
        return servingSizeRepository.findById(servingSizeId)
                .<ResponseEntity<?>>map(servingSize -> {
                    boolean duplicate = servingSizeRepository
                            .findByServingSizeNameIgnoreCase(request.servingSizeName().trim())
                            .filter(existing -> !existing.getServingSizeId().equals(servingSizeId)).isPresent();
                    if (duplicate) {
                        return ResponseEntity.badRequest()
                                .body(Map.of("message", "A serving size with this name already exists"));
                    }
                    apply(servingSize, request);
                    return ResponseEntity.ok(toResponse(servingSizeRepository.saveAndFlush(servingSize)));
                })
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @DeleteMapping("/admin/serving-sizes/{servingSizeId}")
    @ResponseBody
    public ResponseEntity<?> deleteServingSize(@PathVariable Integer servingSizeId) {
        if (!servingSizeRepository.existsById(servingSizeId)) {
            return ResponseEntity.notFound().build();
        }
        try {
            servingSizeRepository.deleteById(servingSizeId);
            servingSizeRepository.flush();
            return ResponseEntity.noContent().build();
        } catch (DataIntegrityViolationException exception) {
            return ResponseEntity.status(409).body(Map.of(
                    "message", "This serving size is used by meal logs. Mark it inactive instead."));
        }
    }

    private void apply(ServingSize servingSize, AdminServingSizeRequest request) {
        servingSize.setServingSizeName(request.servingSizeName().trim());
        servingSize.setMultiplier(request.multiplier());
        servingSize.setDescription(request.description() == null || request.description().isBlank()
                ? null : request.description().trim());
        servingSize.setIsActive(request.active() == null || request.active());
    }

    private Map<String, Object> toResponse(ServingSize servingSize) {
        return Map.of(
                "id", servingSize.getServingSizeId(),
                "servingSizeName", servingSize.getServingSizeName(),
                "multiplier", servingSize.getMultiplier(),
                "description", servingSize.getDescription() == null ? "" : servingSize.getDescription(),
                "active", Boolean.TRUE.equals(servingSize.getIsActive()));
    }
}
