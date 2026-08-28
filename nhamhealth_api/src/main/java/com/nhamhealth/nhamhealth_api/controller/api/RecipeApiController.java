package com.nhamhealth.nhamhealth_api.controller.api;

import static org.springframework.http.HttpStatus.UNAUTHORIZED;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import com.nhamhealth.nhamhealth_api.dto.request.RecipeRequest;
import com.nhamhealth.nhamhealth_api.dto.response.RecipeResponse;
import com.nhamhealth.nhamhealth_api.service.RecipeFlowService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/v1/recipes")
public class RecipeApiController {
    private final RecipeFlowService recipes;
    public RecipeApiController(RecipeFlowService recipes) { this.recipes = recipes; }

    @GetMapping("/mine") public List<RecipeResponse> mine(@AuthenticationPrincipal Jwt jwt) { return recipes.mine(userId(jwt)); }
    @GetMapping("/saved") public List<RecipeResponse> saved(@AuthenticationPrincipal Jwt jwt) { return recipes.saved(userId(jwt)); }
    @GetMapping("/{recipeId}") public RecipeResponse detail(@AuthenticationPrincipal Jwt jwt, @PathVariable Integer recipeId) { return recipes.detail(userId(jwt), recipeId); }
    @PostMapping(consumes = "multipart/form-data") @ResponseStatus(HttpStatus.CREATED)
    public RecipeResponse create(@AuthenticationPrincipal Jwt jwt, @Valid @RequestPart("recipe") RecipeRequest recipe, @RequestPart(value = "image", required = false) MultipartFile image) { return recipes.create(userId(jwt), recipe, image); }
    @PutMapping(value = "/{recipeId}", consumes = "multipart/form-data")
    public RecipeResponse update(@AuthenticationPrincipal Jwt jwt, @PathVariable Integer recipeId, @Valid @RequestPart("recipe") RecipeRequest recipe, @RequestPart(value = "image", required = false) MultipartFile image) { return recipes.update(userId(jwt), recipeId, recipe, image); }
    @PostMapping("/{recipeId}/publish") public RecipeResponse publish(@AuthenticationPrincipal Jwt jwt, @PathVariable Integer recipeId) { return recipes.publish(userId(jwt), recipeId); }
    @PostMapping("/{recipeId}/ai-check") public RecipeResponse aiCheck(@AuthenticationPrincipal Jwt jwt, @PathVariable Integer recipeId) { return recipes.runAiCheck(userId(jwt), recipeId); }
    @PostMapping("/{recipeId}/saved") public RecipeResponse save(@AuthenticationPrincipal Jwt jwt, @PathVariable Integer recipeId) { return recipes.toggleSaved(userId(jwt), recipeId); }
    @DeleteMapping("/{recipeId}/saved") public RecipeResponse unsave(@AuthenticationPrincipal Jwt jwt, @PathVariable Integer recipeId) { return recipes.toggleSaved(userId(jwt), recipeId); }
    private Integer userId(Jwt jwt) { if (jwt == null) throw new ResponseStatusException(UNAUTHORIZED, "Authentication is required."); Number id = jwt.getClaim("userId"); if (id == null) throw new ResponseStatusException(UNAUTHORIZED, "The access token has no user ID."); return id.intValue(); }
}
