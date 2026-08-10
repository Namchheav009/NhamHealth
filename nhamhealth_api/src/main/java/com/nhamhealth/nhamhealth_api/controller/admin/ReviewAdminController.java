package com.nhamhealth.nhamhealth_api.controller.admin;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

import com.nhamhealth.nhamhealth_api.entity.Review;
import com.nhamhealth.nhamhealth_api.repository.ReviewRepository;

@Controller
public class ReviewAdminController {

    private final ReviewRepository reviewRepository;

    public ReviewAdminController(ReviewRepository reviewRepository) {
        this.reviewRepository = reviewRepository;
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

        double averageRating = reviews.stream()
                .filter(r -> r.getRating() != null)
                .mapToInt(review -> review.getRating())
                .average()
                .orElse(0.0);

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

        return "admin/review";
    }

    @DeleteMapping("/admin/reviews/{reviewId}")
    public ResponseEntity<Void> deleteReview(@PathVariable Integer reviewId) {
        if (!reviewRepository.existsById(reviewId)) {
            return ResponseEntity.notFound().build();
        }
        reviewRepository.deleteById(reviewId);
        return ResponseEntity.noContent().build();
    }
}
