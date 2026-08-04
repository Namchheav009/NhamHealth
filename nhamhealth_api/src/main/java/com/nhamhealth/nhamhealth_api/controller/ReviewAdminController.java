package com.nhamhealth.nhamhealth_api.controller;

import java.util.List;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

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
        List<Review> reviews = reviewRepository.findAll();
        long totalReviews = reviews.size();

        long approvedReviews = reviews.stream()
                .filter(this::isApproved)
                .count();

        long reportedReviews = reviews.stream()
                .filter(this::isReported)
                .count();

        double averageRating = reviews.stream()
                .filter(r -> r.getRating() != null)
                .mapToInt(Review::getRating)
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
        model.addAttribute("approvedReviews", approvedReviews);
        model.addAttribute("reportedReviews", reportedReviews);
        model.addAttribute("approvedPercentage",
                totalReviews > 0 ? String.format("%.1f%% of total", approvedReviews * 100.0 / totalReviews)
                        : "0.0% of total");
        model.addAttribute("reportedPercentage",
                totalReviews > 0 ? String.format("%.1f%% of total", reportedReviews * 100.0 / totalReviews)
                        : "0.0% of total");
        model.addAttribute("averageRating", String.format("%.1f / 5", averageRating));
        model.addAttribute("ratingDelta", "+0.2 from last month");
        model.addAttribute("mealsReviewed", mealsReviewed);

        return "admin/review";
    }

    private boolean isApproved(Review review) {
        return !isReported(review);
    }

    private boolean isReported(Review review) {
        return review.getRating() != null && review.getRating() < 3;
    }
}
