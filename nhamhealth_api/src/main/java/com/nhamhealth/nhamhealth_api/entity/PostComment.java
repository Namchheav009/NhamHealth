package com.nhamhealth.nhamhealth_api.entity;

import com.nhamhealth.nhamhealth_api.entity.User;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

@Entity
@Table(name = "post_comments", indexes = {
    @jakarta.persistence.Index(name = "idx_post_comments_post_id_created_at", columnList = "user_meal_post_id, created_at"),
    @jakarta.persistence.Index(name = "idx_post_comments_user_id", columnList = "user_id"),
    @jakarta.persistence.Index(name = "idx_post_comments_parent_comment_id", columnList = "parent_comment_id")
})
public class PostComment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "comment_id")
    private Integer commentId;

    @ManyToOne(fetch = jakarta.persistence.FetchType.LAZY)
    @JoinColumn(name = "user_meal_post_id", nullable = false,
            foreignKey = @jakarta.persistence.ForeignKey(value = jakarta.persistence.ConstraintMode.NO_CONSTRAINT))
    private Post post;

    @ManyToOne(fetch = jakarta.persistence.FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = jakarta.persistence.FetchType.LAZY)
    @JoinColumn(name = "parent_comment_id")
    private PostComment parentComment;

    @Column(name = "comment_text", nullable = false)
    private String commentText;

    @Column(name = "status", nullable = false, length = 20)
    private String status;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    public PostComment() {
    }

    public Integer getCommentId() {
        return commentId;
    }

    public Post getPost() {
        return post;
    }

    public void setPost(Post post) {
        this.post = post;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public PostComment getParentComment() {
        return parentComment;
    }

    public void setParentComment(PostComment parentComment) {
        this.parentComment = parentComment;
    }

    public String getCommentText() {
        return commentText;
    }

    public void setCommentText(String commentText) {
        this.commentText = commentText;
    }

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
