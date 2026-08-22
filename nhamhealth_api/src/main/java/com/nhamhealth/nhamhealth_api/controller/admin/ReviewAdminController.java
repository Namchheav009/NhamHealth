package com.nhamhealth.nhamhealth_api.controller.admin;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseBody;

import jakarta.validation.Valid;

import com.nhamhealth.nhamhealth_api.dto.request.AdminReviewRequest;
import com.nhamhealth.nhamhealth_api.entity.Review;
import com.nhamhealth.nhamhealth_api.repository.ReviewRepository;
import com.nhamhealth.nhamhealth_api.repository.MealRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

@Controller
public class ReviewAdminController {

    private final ReviewRepository reviewRepository;
    private final UserRepository userRepository;
    private final MealRepository mealRepository;

    public ReviewAdminController(ReviewRepository reviewRepository, UserRepository userRepository,
            MealRepository mealRepository) {
        this.reviewRepository = reviewRepository;
        this.userRepository = userRepository;
        this.mealRepository = mealRepository;
    }

    @GetMapping("/admin/reviews")
    public String listReviews(Model model) {
        List<Review> reviews = reviewRepository.findAllByOrderByCreatedAtDesc();
        long totalReviews = reviews.size();

        long positiveReviews = reviews.stream()
                .filter(review -> review.getRating() != null && review.getRating() >= 4)
                .count();

        long lowRatedReviews = reviews.stream()
                .filter(review -> review.getRating() != null && review.getRating() < 3)
                .count();

        double averageRating = reviewRepository.findAverageRating();

        long mealsReviewed = reviews.stream()
                .map(r -> r.getMeal() != null ? r.getMeal().getMealId() : null)
                .filter(id -> id != null)
                .distinct()
                .count();

        model.addAttribute("pageTitle", "Meal Reviews");
        model.addAttribute("reviews", reviews);
        model.addAttribute("totalReviews", totalReviews);
        model.addAttribute("positiveReviews", positiveReviews);
        model.addAttribute("lowRatedReviews", lowRatedReviews);
        model.addAttribute("positivePercentage",
                totalReviews > 0 ? String.format("%.1f%% of total", positiveReviews * 100.0 / totalReviews)
                        : "0.0% of total");
        model.addAttribute("averageRating", String.format("%.1f / 5", averageRating));
        model.addAttribute("mealsReviewed", mealsReviewed);
        model.addAttribute("users", userRepository.findAll());
        model.addAttribute("meals", mealRepository.findAll());

        return "admin/review";
    }

    @PostMapping("/admin/reviews")
    @ResponseBody
    public ResponseEntity<?> createReview(@Valid @RequestBody AdminReviewRequest request) {
        return saveReview(new Review(), request, true);
    }

    @PutMapping("/admin/reviews/{reviewId}")
    @ResponseBody
    public ResponseEntity<?> updateReview(@PathVariable Integer reviewId,
            @Valid @RequestBody AdminReviewRequest request) {
        Review review = reviewRepository.findById(reviewId).orElse(null);
        if (review == null) return ResponseEntity.notFound().build();
        return saveReview(review, request, false);
    }

    private ResponseEntity<?> saveReview(Review review, AdminReviewRequest request, boolean creating) {
        var user = userRepository.findById(request.userId()).orElse(null);
        var meal = mealRepository.findById(request.mealId()).orElse(null);
        if (user == null) return ResponseEntity.badRequest().body(message("Selected user was not found."));
        if (meal == null) return ResponseEntity.badRequest().body(message("Selected meal was not found."));
        review.setUser(user);
        review.setMeal(meal);
        review.setRating(request.rating());
        review.setReviewText(request.reviewText() == null ? null : request.reviewText().trim());
        if (creating) review.setCreatedAt(LocalDateTime.now());
        else review.setUpdatedAt(LocalDateTime.now());
        Review saved = reviewRepository.save(review);
        return ResponseEntity.ok(Map.of(
                "message", "Review saved successfully.",
                "reviewId", saved.getReviewId()));
    }

    private Map<String, String> message(String value) {
        return Map.of("message", value);
    }

    @DeleteMapping("/admin/reviews/{reviewId}")
    @ResponseBody
    public ResponseEntity<Void> deleteReview(@PathVariable Integer reviewId) {
        if (!reviewRepository.existsById(reviewId)) {
            return ResponseEntity.notFound().build();
        }
        reviewRepository.deleteById(reviewId);
        return ResponseEntity.noContent().build();
    }
}
