package com.nhamhealth.nhamhealth_api.service.catalog;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Objects;

import jakarta.persistence.EntityManager;

import com.nhamhealth.nhamhealth_api.dto.request.AdminIngredientRequest;
import com.nhamhealth.nhamhealth_api.dto.response.AdminIngredientDto;
import com.nhamhealth.nhamhealth_api.entity.Ingredient;
import com.nhamhealth.nhamhealth_api.repository.catalog.IngredientRepository;

@Service
public class IngredientAdminService {

    private final IngredientRepository ingredientRepository;
    private final EntityManager entityManager;

    public IngredientAdminService(IngredientRepository ingredientRepository, EntityManager entityManager) {
        this.ingredientRepository = ingredientRepository;
        this.entityManager = entityManager;
    }

    @Transactional
    public AdminIngredientDto create(AdminIngredientRequest request) {
        String name = request.ingredientName().trim();
        if (ingredientRepository.findByIngredientNameIgnoreCase(name).isPresent()) {
            throw new IllegalArgumentException("An ingredient with this name already exists");
        }
        Ingredient ingredient = new Ingredient();
        apply(ingredient, request);
        return toDto(ingredientRepository.save(ingredient));
    }

    @Transactional
    public AdminIngredientDto update(Integer ingredientId, AdminIngredientRequest request) {
        Ingredient ingredient = findIngredient(ingredientId);
        String name = request.ingredientName().trim();
        ingredientRepository.findByIngredientNameIgnoreCase(name)
                .filter(existing -> !existing.getIngredientId().equals(ingredientId))
                .ifPresent(existing -> { throw new IllegalArgumentException("An ingredient with this name already exists"); });
        apply(ingredient, request);
        return toDto(ingredientRepository.save(ingredient));
    }

    @Transactional
    public void delete(Integer ingredientId) {
        Ingredient ingredient = findIngredient(ingredientId);
        Number mealReferences = (Number) entityManager.createNativeQuery(
                "SELECT COUNT(*) FROM meal_ingredients WHERE ingredient_id = :ingredientId")
                .setParameter("ingredientId", ingredientId)
                .getSingleResult();
        if (mealReferences.longValue() > 0) {
            throw new IllegalArgumentException("This ingredient is used by meals and cannot be deleted");
        }
        ingredientRepository.delete(ingredient);
    }

    @Transactional(readOnly = true)
    public List<AdminIngredientDto> search(String query) {
        String normalizedQuery = query == null ? "" : query.trim();
        List<Ingredient> ingredients = normalizedQuery.isEmpty()
                ? ingredientRepository.findAllByOrderByIngredientNameAsc().stream().limit(20).toList()
                : ingredientRepository.findTop20ByIngredientNameContainingIgnoreCaseOrderByIngredientNameAsc(normalizedQuery);
        return ingredients.stream().map(this::toDto).toList();
    }

    @Transactional(readOnly = true)
    public List<String> getDefaultUnits() {
        return ingredientRepository.findAllByOrderByIngredientNameAsc().stream()
                .map(Ingredient::getDefaultUnit)
                .filter(Objects::nonNull)
                .map(String::trim)
                .filter(unit -> !unit.isEmpty())
                .distinct()
                .sorted(String.CASE_INSENSITIVE_ORDER)
                .toList();
    }

    private Ingredient findIngredient(Integer ingredientId) {
        return ingredientRepository.findById(ingredientId)
                .orElseThrow(() -> new IllegalArgumentException("Ingredient was not found"));
    }

    private void apply(Ingredient ingredient, AdminIngredientRequest request) {
        ingredient.setIngredientName(request.ingredientName().trim());
        ingredient.setIngredientType(request.ingredientType().trim());
        ingredient.setDefaultUnit(blankToNull(request.defaultUnit()));
        ingredient.setDescription(blankToNull(request.description()));
        ingredient.setImageUrl(blankToNull(request.imageUrl()));
    }

    private String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private AdminIngredientDto toDto(Ingredient ingredient) {
        return new AdminIngredientDto(
                ingredient.getIngredientId(), ingredient.getIngredientName(), ingredient.getIngredientType(),
                ingredient.getDefaultUnit(), ingredient.getDescription(), ingredient.getImageUrl());
    }
}
