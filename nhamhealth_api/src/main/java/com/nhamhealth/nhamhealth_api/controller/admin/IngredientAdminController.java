package com.nhamhealth.nhamhealth_api.controller.admin;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.multipart.MultipartFile;

import jakarta.validation.Valid;

import com.nhamhealth.nhamhealth_api.dto.request.AdminIngredientRequest;
import com.nhamhealth.nhamhealth_api.dto.response.AdminIngredientDto;
import com.nhamhealth.nhamhealth_api.entity.Ingredient;
import com.nhamhealth.nhamhealth_api.repository.catalog.IngredientRepository;
import com.nhamhealth.nhamhealth_api.service.catalog.IngredientAdminService;
import com.nhamhealth.nhamhealth_api.service.user.ProfileImageStorageService;

@Controller
public class IngredientAdminController {

    private final IngredientRepository ingredientRepository;
    private final IngredientAdminService ingredientAdminService;
    private final ProfileImageStorageService profileImageStorageService;

    public IngredientAdminController(
            IngredientRepository ingredientRepository,
            IngredientAdminService ingredientAdminService,
            ProfileImageStorageService profileImageStorageService) {
        this.ingredientRepository = ingredientRepository;
        this.ingredientAdminService = ingredientAdminService;
        this.profileImageStorageService = profileImageStorageService;
    }

    @GetMapping("/admin/ingredients")
    public String ingredients(Authentication authentication, Model model) {
        List<Ingredient> ingredients = ingredientRepository.findAllByOrderByIngredientNameAsc();

        model.addAttribute("pageTitle", "Ingredients");
        model.addAttribute("activePage", "ingredients");
        model.addAttribute("adminName", authentication.getName());
        model.addAttribute("ingredients", ingredients);
        model.addAttribute("totalIngredients", ingredientRepository.count());
        return "admin/ingredients";
    }

    @GetMapping("/admin/ingredients/search")
    @ResponseBody
    public ResponseEntity<List<AdminIngredientDto>> searchIngredients(
            @RequestParam(value = "q", required = false) String query) {
        return ResponseEntity.ok(ingredientAdminService.search(query));
    }

    @PostMapping("/admin/ingredients")
    @ResponseBody
    public ResponseEntity<?> createIngredient(@Valid @RequestBody AdminIngredientRequest request) {
        try {
            return ResponseEntity.status(HttpStatus.CREATED).body(ingredientAdminService.create(request));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(java.util.Map.of("message", exception.getMessage()));
        }
    }

    @PutMapping("/admin/ingredients/{ingredientId}")
    @ResponseBody
    public ResponseEntity<?> updateIngredient(
            @PathVariable Integer ingredientId,
            @Valid @RequestBody AdminIngredientRequest request) {
        try {
            return ResponseEntity.ok(ingredientAdminService.update(ingredientId, request));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(java.util.Map.of("message", exception.getMessage()));
        }
    }

    @DeleteMapping("/admin/ingredients/{ingredientId}")
    @ResponseBody
    public ResponseEntity<?> deleteIngredient(@PathVariable Integer ingredientId) {
        try {
            ingredientAdminService.delete(ingredientId);
            return ResponseEntity.noContent().build();
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(java.util.Map.of("message", exception.getMessage()));
        }
    }

    @PostMapping(value = "/admin/ingredient-images", consumes = "multipart/form-data")
    @ResponseBody
    public ResponseEntity<?> uploadIngredientImage(@RequestParam("file") MultipartFile file) {
        try {
            return ResponseEntity.ok(java.util.Map.of("imageUrl", profileImageStorageService.storeIngredientImage(file)));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(java.util.Map.of("message", exception.getMessage()));
        } catch (IllegalStateException exception) {
            return ResponseEntity.internalServerError().body(java.util.Map.of("message", exception.getMessage()));
        }
    }
}
