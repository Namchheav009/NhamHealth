package com.nhamhealth.nhamhealth_api.service.community;
import com.nhamhealth.nhamhealth_api.service.user.ProfileImageStorageService;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import com.nhamhealth.nhamhealth_api.dto.response.CommunityPostResponse;
import com.nhamhealth.nhamhealth_api.entity.Post;
import com.nhamhealth.nhamhealth_api.entity.Recipe;
import com.nhamhealth.nhamhealth_api.entity.RecipeTag;
import com.nhamhealth.nhamhealth_api.entity.TagType;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.community.CommentLikeRepository;
import com.nhamhealth.nhamhealth_api.repository.community.FollowRepository;
import com.nhamhealth.nhamhealth_api.repository.community.PostCommentRepository;
import com.nhamhealth.nhamhealth_api.repository.community.PostLikeRepository;
import com.nhamhealth.nhamhealth_api.repository.community.PostMediaRepository;
import com.nhamhealth.nhamhealth_api.repository.community.PostRepository;
import com.nhamhealth.nhamhealth_api.repository.community.PostTagRepository;
import com.nhamhealth.nhamhealth_api.repository.recipe.RecipeIngredientRepository;
import com.nhamhealth.nhamhealth_api.repository.recipe.RecipeRepository;
import com.nhamhealth.nhamhealth_api.repository.recipe.RecipeStepRepository;
import com.nhamhealth.nhamhealth_api.repository.recipe.RecipeTagRepository;
import com.nhamhealth.nhamhealth_api.repository.recipe.SavedRecipeRepository;
import com.nhamhealth.nhamhealth_api.repository.catalog.TagTypeRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserProfileRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;

class CommunityServiceVisibilityTests {

    @Test
    void commentsDoNotExposeAnotherUsersOnlyMePost() {
        Dependencies dependencies = new Dependencies();
        Post post = post(42, 7, "ACTIVE", "ONLY_ME");
        when(dependencies.posts.findById(42)).thenReturn(Optional.of(post));
        when(dependencies.follows.findByFollowerUserUserId(9)).thenReturn(List.of());
        when(dependencies.follows.findByFollowingUserUserId(9)).thenReturn(List.of());

        ResponseStatusException error = assertThrows(ResponseStatusException.class,
                () -> dependencies.service.comments(9, 42));

        assertEquals(HttpStatus.NOT_FOUND, error.getStatusCode());
        verifyNoInteractions(dependencies.comments);
    }

    @Test
    void likesDoNotReactivateInteractionWithDeletedPosts() {
        Dependencies dependencies = new Dependencies();
        Post deletedPost = post(42, 7, "DELETED", "PUBLIC");
        when(dependencies.posts.findById(42)).thenReturn(Optional.of(deletedPost));

        ResponseStatusException error = assertThrows(ResponseStatusException.class,
                () -> dependencies.service.toggleLike(9, 42));

        assertEquals(HttpStatus.NOT_FOUND, error.getStatusCode());
        verifyNoInteractions(dependencies.likes);
    }

    @Test
    void deletedPostsCannotBeEditedOrDeletedAgain() {
        Dependencies dependencies = new Dependencies();
        Post deletedPost = post(42, 7, "DELETED", "PUBLIC");
        when(dependencies.posts.findById(42)).thenReturn(Optional.of(deletedPost));

        ResponseStatusException error = assertThrows(ResponseStatusException.class,
                () -> dependencies.service.delete(7, 42));

        assertEquals(HttpStatus.NOT_FOUND, error.getStatusCode());
        verify(dependencies.posts, never()).save(deletedPost);
    }

    @Test
    void mealPostResponsesReturnTagsSavedWithTheRecipe() {
        Dependencies dependencies = new Dependencies();
        Post post = post(42, 7, "ACTIVE", "PUBLIC");
        Recipe recipe = mock(Recipe.class);
        RecipeTag recipeTag = mock(RecipeTag.class);
        TagType tag = mock(TagType.class);
        when(post.getRecipe()).thenReturn(recipe);
        when(recipe.getRecipeId()).thenReturn(42);
        when(recipeTag.getTag()).thenReturn(tag);
        when(tag.getTagId()).thenReturn(3);
        when(tag.getTagName()).thenReturn("Vegan");
        when(dependencies.posts.findById(42)).thenReturn(Optional.of(post));
        when(dependencies.follows.findByFollowerUserUserId(7)).thenReturn(List.of());
        when(dependencies.follows.findByFollowingUserUserId(7)).thenReturn(List.of());
        when(dependencies.media.findByPostPostIdOrderByDisplayOrder(42)).thenReturn(List.of());
        when(dependencies.profiles.findByUser_UserId(7)).thenReturn(Optional.empty());
        when(dependencies.recipeTags.findByRecipeRecipeId(42)).thenReturn(List.of(recipeTag));
        when(dependencies.recipeIngredients.findByRecipeRecipeIdOrderByDisplayOrderAsc(42)).thenReturn(List.of());
        when(dependencies.recipeSteps.findByRecipeRecipeIdOrderByStepNumberAsc(42)).thenReturn(List.of());

        CommunityPostResponse response = dependencies.service.postDetails(7, 42);

        assertEquals(List.of("Vegan"), response.tags());
        assertEquals(List.of(3), response.tagIds());
    }

    private static Post post(int postId, int ownerId, String status, String visibility) {
        Post post = mock(Post.class);
        User owner = mock(User.class);
        when(owner.getUserId()).thenReturn(ownerId);
        when(post.getPostId()).thenReturn(postId);
        when(post.getUser()).thenReturn(owner);
        when(post.getStatus()).thenReturn(status);
        when(post.getVisibility()).thenReturn(visibility);
        return post;
    }

    private static final class Dependencies {
        private final PostRepository posts = mock(PostRepository.class);
        private final PostMediaRepository media = mock(PostMediaRepository.class);
        private final PostLikeRepository likes = mock(PostLikeRepository.class);
        private final PostCommentRepository comments = mock(PostCommentRepository.class);
        private final CommentLikeRepository commentLikes = mock(CommentLikeRepository.class);
        private final UserRepository users = mock(UserRepository.class);
        private final UserProfileRepository profiles = mock(UserProfileRepository.class);
        private final FollowRepository follows = mock(FollowRepository.class);
        private final PostTagRepository postTags = mock(PostTagRepository.class);
        private final TagTypeRepository tagTypes = mock(TagTypeRepository.class);
        private final ProfileImageStorageService imageStorage = mock(ProfileImageStorageService.class);
        private final CommunityNotificationService notifications = mock(CommunityNotificationService.class);
        private final RecipeIngredientRepository recipeIngredients = mock(RecipeIngredientRepository.class);
        private final RecipeStepRepository recipeSteps = mock(RecipeStepRepository.class);
        private final RecipeTagRepository recipeTags = mock(RecipeTagRepository.class);
        private final RecipeRepository recipes = mock(RecipeRepository.class);
        private final SavedRecipeRepository savedRecipes = mock(SavedRecipeRepository.class);
        private final CommunityService service = new CommunityService(posts, media, likes, comments,
                commentLikes, users, profiles, follows, postTags, tagTypes, imageStorage, notifications,
                recipeIngredients, recipeSteps, recipeTags, recipes, savedRecipes);
    }
}
