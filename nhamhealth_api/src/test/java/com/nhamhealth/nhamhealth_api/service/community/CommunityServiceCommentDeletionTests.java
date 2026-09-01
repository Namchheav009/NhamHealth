package com.nhamhealth.nhamhealth_api.service.community;
import com.nhamhealth.nhamhealth_api.service.user.ProfileImageStorageService;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import com.nhamhealth.nhamhealth_api.entity.Post;
import com.nhamhealth.nhamhealth_api.entity.PostComment;
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

class CommunityServiceCommentDeletionTests {

    @Test
    void commentAuthorCanDeleteTheirComment() {
        Dependencies dependencies = new Dependencies(7, 9);

        dependencies.service.deleteComment(9, 42, 100);

        verify(dependencies.comments).delete(dependencies.comment);
    }

    @Test
    void postOwnerCanDeleteAnotherUsersComment() {
        Dependencies dependencies = new Dependencies(7, 9);

        dependencies.service.deleteComment(7, 42, 100);

        verify(dependencies.comments).delete(dependencies.comment);
    }

    @Test
    void unrelatedUserCannotDeleteComment() {
        Dependencies dependencies = new Dependencies(7, 9);

        ResponseStatusException error = assertThrows(ResponseStatusException.class,
                () -> dependencies.service.deleteComment(10, 42, 100));

        assertEquals(HttpStatus.FORBIDDEN, error.getStatusCode());
        verify(dependencies.comments, never()).delete(dependencies.comment);
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
        private final PostComment comment = mock(PostComment.class);

        private Dependencies(int postOwnerId, int commentAuthorId) {
            User postOwner = user(postOwnerId);
            User commentAuthor = user(commentAuthorId);
            Post post = mock(Post.class);
            when(post.getPostId()).thenReturn(42);
            when(post.getUser()).thenReturn(postOwner);
            when(post.getStatus()).thenReturn("ACTIVE");
            when(post.getVisibility()).thenReturn("PUBLIC");
            when(comment.getPost()).thenReturn(post);
            when(comment.getUser()).thenReturn(commentAuthor);
            when(comment.getStatus()).thenReturn("ACTIVE");
            when(posts.findById(42)).thenReturn(Optional.of(post));
            when(comments.findById(100)).thenReturn(Optional.of(comment));
        }

        private static User user(int id) {
            User user = mock(User.class);
            when(user.getUserId()).thenReturn(id);
            return user;
        }
    }
}
