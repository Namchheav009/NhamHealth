package com.nhamhealth.nhamhealth_api.service.community;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.Optional;

import org.junit.jupiter.api.Test;

import com.nhamhealth.nhamhealth_api.entity.Post;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.catalog.TagTypeRepository;
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
import com.nhamhealth.nhamhealth_api.repository.user.UserProfileRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.service.user.ProfileImageStorageService;

class CommunityServiceToggleLikeTests {

    @Test
    void unlikesPostWhenAlreadyLiked() {
        Dependencies deps = new Dependencies();
        when(deps.likes.deleteByUserUserIdAndPostPostId(9, 20)).thenReturn(1);

        deps.service.toggleLike(9, 20);

        verify(deps.likes).deleteByUserUserIdAndPostPostId(9, 20);
        verify(deps.likes, never()).insertIgnoreConflict(any(), any(), any());
        verify(deps.notifications, never()).postLiked(any(), any());
    }

    @Test
    void likesPostWhenNotLikedAndSendsNotification() {
        Dependencies deps = new Dependencies();
        when(deps.likes.deleteByUserUserIdAndPostPostId(9, 20)).thenReturn(0);
        when(deps.likes.insertIgnoreConflict(eq(9), eq(20), any())).thenReturn(1);

        deps.service.toggleLike(9, 20);

        verify(deps.likes).deleteByUserUserIdAndPostPostId(9, 20);
        verify(deps.likes).insertIgnoreConflict(eq(9), eq(20), any());
        verify(deps.notifications).postLiked(eq(deps.actor), eq(deps.post));
    }

    @Test
    void handlesConcurrentConflictSilentlyWithoutDuplicateNotification() {
        Dependencies deps = new Dependencies();
        when(deps.likes.deleteByUserUserIdAndPostPostId(9, 20)).thenReturn(0);
        // insertIgnoreConflict returns 0 when concurrent insert won the race (conflict DO NOTHING)
        when(deps.likes.insertIgnoreConflict(eq(9), eq(20), any())).thenReturn(0);

        var response = deps.service.toggleLike(9, 20);

        assertNotNull(response);
        verify(deps.likes).deleteByUserUserIdAndPostPostId(9, 20);
        verify(deps.likes).insertIgnoreConflict(eq(9), eq(20), any());
        // Notification must NOT be sent twice
        verify(deps.notifications, never()).postLiked(any(), any());
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

        private final User postOwner = mock(User.class);
        private final User actor = mock(User.class);
        private final Post post = mock(Post.class);

        private Dependencies() {
            when(postOwner.getUserId()).thenReturn(1);
            when(actor.getUserId()).thenReturn(9);
            when(post.getPostId()).thenReturn(20);
            when(post.getUser()).thenReturn(postOwner);
            when(post.getStatus()).thenReturn("ACTIVE");
            when(post.getVisibility()).thenReturn("PUBLIC");
            when(posts.findById(20)).thenReturn(Optional.of(post));
            when(users.findById(9)).thenReturn(Optional.of(actor));
        }
    }
}
