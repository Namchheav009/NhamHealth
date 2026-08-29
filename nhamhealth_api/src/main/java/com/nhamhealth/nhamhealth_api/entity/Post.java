package com.nhamhealth.nhamhealth_api.entity;

import com.nhamhealth.nhamhealth_api.entity.User;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

@Entity
@org.hibernate.annotations.Immutable
@Table(name = "community_meal_posts")
public class Post {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "post_id")
    private Integer postId;

    @ManyToOne(fetch = jakarta.persistence.FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false,
            foreignKey = @jakarta.persistence.ForeignKey(
                    value = jakarta.persistence.ConstraintMode.NO_CONSTRAINT))
    private User user;

    @ManyToOne(fetch = jakarta.persistence.FetchType.LAZY)
    @JoinColumn(name = "tagged_meal_id",
            foreignKey = @jakarta.persistence.ForeignKey(
                    value = jakarta.persistence.ConstraintMode.NO_CONSTRAINT))
    private Meal taggedMeal;

    /** Compatibility mapping to the user meal post that is itself being displayed. */
    @OneToOne(fetch = jakarta.persistence.FetchType.LAZY)
    @JoinColumn(name = "user_meal_post_id", unique = true,
            foreignKey = @jakarta.persistence.ForeignKey(
                    value = jakarta.persistence.ConstraintMode.NO_CONSTRAINT))
    private Recipe recipe;

    @Column(name = "caption")
    private String caption;

    @Column(name = "visibility", nullable = false, length = 20)
    private String visibility;

    @Column(name = "allow_comments", nullable = false)
    private boolean allowComments = true;

    @Column(name = "allow_replies", nullable = false)
    private boolean allowReplies = true;

    @Column(name = "status", nullable = false, length = 20)
    private String status;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    public Post() {
    }

    public Integer getPostId() {
        return postId;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public Meal getTaggedMeal() {
        return taggedMeal;
    }

    public void setTaggedMeal(Meal taggedMeal) {
        this.taggedMeal = taggedMeal;
    }

    public Recipe getRecipe() {
        return recipe;
    }

    public void setRecipe(Recipe recipe) {
        this.recipe = recipe;
    }

    public String getCaption() {
        return caption;
    }

    public void setCaption(String caption) {
        this.caption = caption;
    }

    public String getVisibility() {
        return visibility;
    }

    public void setVisibility(String visibility) {
        this.visibility = visibility;
    }

    public boolean isAllowComments() { return allowComments; }

    public void setAllowComments(boolean allowComments) { this.allowComments = allowComments; }

    public boolean isAllowReplies() { return allowReplies; }

    public void setAllowReplies(boolean allowReplies) { this.allowReplies = allowReplies; }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
