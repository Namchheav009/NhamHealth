package com.nhamhealth.nhamhealth_api.repository.community;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;

import java.time.LocalDateTime;

import jakarta.persistence.EntityManager;
import org.hibernate.Hibernate;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;
import org.springframework.cache.CacheManager;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

import com.nhamhealth.nhamhealth_api.entity.Recipe;
import com.nhamhealth.nhamhealth_api.entity.Role;
import com.nhamhealth.nhamhealth_api.entity.User;

@DataJpaTest
class PostLikeRepositoryPersistenceTests {
    @MockitoBean private CacheManager cacheManager;
    @Autowired private EntityManager entityManager;
    @Autowired private PostLikeRepository likes;

    @Test
    void deletingLikesKeepsLazyRecipeAccessibleForResponse() {
        Role role = new Role();
        role.setRoleName("RECIPE_TEST");
        entityManager.persist(role);
        User author = new User();
        author.setRole(role);
        author.setStatus("ACTIVE");
        author.setIsVerified(true);
        entityManager.persist(author);
        Recipe recipe = new Recipe();
        recipe.setAuthor(author);
        recipe.setRecipeName("Test recipe");
        recipe.setCreatedAt(LocalDateTime.now());
        recipe.setUpdatedAt(LocalDateTime.now());
        entityManager.persist(recipe);
        entityManager.flush();
        Integer recipeId = recipe.getRecipeId();
        Integer authorId = author.getUserId();
        entityManager.clear();

        Recipe lazyRecipe = entityManager.getReference(Recipe.class, recipeId);
        assertFalse(Hibernate.isInitialized(lazyRecipe));

        // The first operation on every like toggle must not detach its recipe,
        // even when there is no existing like to delete.
        assertEquals(0, likes.deleteByUserUserIdAndPostPostId(authorId, recipeId));

        assertEquals("Test recipe", lazyRecipe.getRecipeName());
        assertEquals("ACTIVE", lazyRecipe.getAuthor().getStatus());
    }
}
