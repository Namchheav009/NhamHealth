package com.nhamhealth.nhamhealth_api.service.community;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;

import com.nhamhealth.nhamhealth_api.dto.response.CommunityPersonResponse;
import com.nhamhealth.nhamhealth_api.entity.Follow;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.catalog.TagTypeRepository;
import com.nhamhealth.nhamhealth_api.repository.community.CommentLikeRepository;
import com.nhamhealth.nhamhealth_api.repository.community.FollowRepository;
import com.nhamhealth.nhamhealth_api.repository.community.ModerationActionRepository;
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

class CommunityServiceFollowTests {

    @Test
    void followingSomeoneWhoFollowsViewerReturnsFriend() {
        Dependencies dependencies = new Dependencies();
        User viewer = user(1, "Viewer");
        User target = user(2, "Target");
        when(dependencies.users.findById(1)).thenReturn(Optional.of(viewer));
        when(dependencies.users.findById(2)).thenReturn(Optional.of(target));
        when(dependencies.follows.findFirstByFollowerUserUserIdAndFollowingUserUserIdAndStatusIgnoreCaseOrderByFollowIdAsc(
                1, 2, "ACTIVE"))
                .thenReturn(Optional.empty());
        when(dependencies.follows.existsByFollowerUserUserIdAndFollowingUserUserIdAndStatusIgnoreCase(
                2, 1, "ACTIVE")).thenReturn(true);

        assertEquals("FRIEND", dependencies.service.toggleFollow(1, 2));
        verify(dependencies.communityNotifications).followedBack(viewer, target);
    }

    @Test
    void followingSomeoneWhoDoesNotFollowViewerSendsFollowed() {
        Dependencies dependencies = new Dependencies();
        User viewer = user(1, "Viewer");
        User target = user(2, "Target");
        when(dependencies.users.findById(1)).thenReturn(Optional.of(viewer));
        when(dependencies.users.findById(2)).thenReturn(Optional.of(target));
        when(dependencies.follows.findFirstByFollowerUserUserIdAndFollowingUserUserIdAndStatusIgnoreCaseOrderByFollowIdAsc(
                1, 2, "ACTIVE"))
                .thenReturn(Optional.empty());
        when(dependencies.follows.existsByFollowerUserUserIdAndFollowingUserUserIdAndStatusIgnoreCase(
                2, 1, "ACTIVE")).thenReturn(false);

        assertEquals("FOLLOWING", dependencies.service.toggleFollow(1, 2));
        verify(dependencies.communityNotifications).followed(viewer, target);
    }

    @Test
    void unfollowingFriendRemovesBothFollowsSoTheyMustAddBackToBeFriend() {
        Dependencies dependencies = new Dependencies();
        Follow existing = follow(user(1, "Viewer"), user(2, "Target"));
        Follow reverse = follow(user(2, "Target"), user(1, "Viewer"));
        when(dependencies.follows.findFirstByFollowerUserUserIdAndFollowingUserUserIdAndStatusIgnoreCaseOrderByFollowIdAsc(
                1, 2, "ACTIVE"))
                .thenReturn(Optional.of(existing));
        when(dependencies.follows.existsByFollowerUserUserIdAndFollowingUserUserIdAndStatusIgnoreCase(
                2, 1, "ACTIVE")).thenReturn(true);
        when(dependencies.follows.findFirstByFollowerUserUserIdAndFollowingUserUserIdAndStatusIgnoreCaseOrderByFollowIdAsc(
                2, 1, "ACTIVE"))
                .thenReturn(Optional.of(reverse));

        assertEquals("NONE", dependencies.service.toggleFollow(1, 2));
        verify(dependencies.follows).delete(existing);
        verify(dependencies.follows).delete(reverse);
    }

    @Test
    void unfollowingOneWayFollowingDeletesOnlyViewerFollow() {
        Dependencies dependencies = new Dependencies();
        Follow existing = follow(user(1, "Viewer"), user(2, "Target"));
        when(dependencies.follows.findFirstByFollowerUserUserIdAndFollowingUserUserIdAndStatusIgnoreCaseOrderByFollowIdAsc(
                1, 2, "ACTIVE"))
                .thenReturn(Optional.of(existing));
        when(dependencies.follows.existsByFollowerUserUserIdAndFollowingUserUserIdAndStatusIgnoreCase(
                2, 1, "ACTIVE")).thenReturn(false);

        assertEquals("NONE", dependencies.service.toggleFollow(1, 2));
        verify(dependencies.follows).delete(existing);
    }

    @Test
    void removeFollowerDeletesInboundFollow() {
        Dependencies dependencies = new Dependencies();
        Follow existing = follow(user(5, "Follower Only"), user(1, "Viewer"));
        when(dependencies.follows.findFirstByFollowerUserUserIdAndFollowingUserUserIdAndStatusIgnoreCaseOrderByFollowIdAsc(
                5, 1, "ACTIVE"))
                .thenReturn(Optional.of(existing));

        dependencies.service.removeFollower(1, 5);
        verify(dependencies.follows).delete(existing);
    }

    @Test
    void peopleReturnsActualSharedFriendCount() {
        Dependencies dependencies = new Dependencies();
        User viewer = user(1, "Viewer");
        User target = user(2, "Target");
        User sharedFriend = user(3, "Shared Friend");
        User followingOnly = user(4, "Following Only");
        User followerOnly = user(5, "Follower Only");
        when(dependencies.users.findAll()).thenReturn(List.of(
                viewer, target, sharedFriend, followingOnly, followerOnly));
        when(dependencies.profiles.findByUser_UserIdIn(List.of(1, 2, 3, 4, 5))).thenReturn(List.of());
        when(dependencies.follows.findByStatusIgnoreCase("ACTIVE")).thenReturn(List.of(
                follow(viewer, sharedFriend),
                follow(sharedFriend, viewer),
                follow(target, sharedFriend),
                follow(sharedFriend, target),
                follow(viewer, followingOnly),
                follow(followerOnly, viewer)));

        List<CommunityPersonResponse> discover = dependencies.service.people(1, "discover");
        CommunityPersonResponse response = discover.stream()
                .filter(person -> person.id().equals(2))
                .findFirst()
                .orElseThrow();

        assertEquals(1, response.mutualFriends());
        assertEquals("NONE", response.connectionStatus());
        assertEquals(List.of(2, 3, 4, 5), discover.stream().map(CommunityPersonResponse::id).toList());
        assertEquals(List.of(3), dependencies.service.people(1, "friends").stream()
                .map(CommunityPersonResponse::id).toList());
        assertEquals(List.of(5), dependencies.service.people(1, "followers").stream()
                .map(CommunityPersonResponse::id).toList());
        assertEquals(List.of(4), dependencies.service.people(1, "following").stream()
                .map(CommunityPersonResponse::id).toList());
    }

    private static User user(int id, String name) {
        User user = mock(User.class);
        when(user.getUserId()).thenReturn(id);
        when(user.getName()).thenReturn(name);
        when(user.getEmail()).thenReturn(name.toLowerCase().replace(' ', '.') + "@example.com");
        return user;
    }

    private static Follow follow(User follower, User following) {
        Follow follow = new Follow();
        follow.setFollowerUser(follower);
        follow.setFollowingUser(following);
        follow.setStatus("ACTIVE");
        return follow;
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
        private final CommunityNotificationService communityNotifications = mock(CommunityNotificationService.class);
        private final RecipeIngredientRepository recipeIngredients = mock(RecipeIngredientRepository.class);
        private final RecipeStepRepository recipeSteps = mock(RecipeStepRepository.class);
        private final RecipeTagRepository recipeTags = mock(RecipeTagRepository.class);
        private final RecipeRepository recipes = mock(RecipeRepository.class);
        private final SavedRecipeRepository savedRecipes = mock(SavedRecipeRepository.class);
        private final ModerationActionRepository moderationActions = mock(ModerationActionRepository.class);
        private final CommunityService service = new CommunityService(posts, media, likes, comments,
                commentLikes, users, profiles, follows, postTags, tagTypes, imageStorage, communityNotifications,
                recipeIngredients, recipeSteps, recipeTags, recipes, savedRecipes, moderationActions);
    }
}
