package com.nhamhealth.nhamhealth_api.controller.api;

import static org.springframework.http.HttpStatus.UNAUTHORIZED;

import java.time.LocalDate;
import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import com.nhamhealth.nhamhealth_api.dto.request.MealPlanBulkDeleteRequest;
import com.nhamhealth.nhamhealth_api.dto.request.MealPlanBulkStatusRequest;
import com.nhamhealth.nhamhealth_api.dto.request.MealPlanRequest;
import com.nhamhealth.nhamhealth_api.dto.request.MealPlanUpdateRequest;
import com.nhamhealth.nhamhealth_api.dto.response.MealPlanResponse;
import com.nhamhealth.nhamhealth_api.service.meal.MealPlannerService;

import jakarta.validation.Valid;

@RestController
@RequestMapping({ "/api/v1/meal-plans", "/api/meal-plans" })
public class MealPlannerApiController {
    private final MealPlannerService planner;

    public MealPlannerApiController(MealPlannerService planner) {
        this.planner = planner;
    }

    @GetMapping
    public List<MealPlanResponse> range(@AuthenticationPrincipal Jwt jwt,
            @RequestParam LocalDate startDate,
            @RequestParam(required = false) LocalDate endDate,
            @RequestParam(required = false) Integer days,
            @RequestParam(defaultValue = "en") String lang) {
        LocalDate effectiveEnd = endDate != null ? endDate
                : (days != null && days > 0 ? startDate.plusDays(days - 1L) : startDate.plusDays(6));
        return planner.range(userId(jwt), startDate, effectiveEnd, lang);
    }

    @GetMapping("/day")
    public List<MealPlanResponse> day(@AuthenticationPrincipal Jwt jwt,
            @RequestParam LocalDate date,
            @RequestParam(defaultValue = "en") String lang) {
        return planner.day(userId(jwt), date, lang);
    }

    @GetMapping("/week")
    public List<MealPlanResponse> week(@AuthenticationPrincipal Jwt jwt,
            @RequestParam LocalDate startDate, @RequestParam(defaultValue = "en") String lang) {
        return planner.week(userId(jwt), startDate, lang);
    }

    @PostMapping
    public MealPlanResponse add(@AuthenticationPrincipal Jwt jwt, @Valid @RequestBody MealPlanRequest request,
            @RequestParam(defaultValue = "en") String lang) {
        return planner.addOrReplace(userId(jwt), request, lang);
    }

    @PostMapping("/bulk")
    public List<MealPlanResponse> bulkAdd(@AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody List<MealPlanRequest> requests,
            @RequestParam(defaultValue = "en") String lang) {
        return planner.bulkAddOrReplace(userId(jwt), requests, lang);
    }

    @PutMapping("/bulk/status")
    public List<MealPlanResponse> updateStatusBulk(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody MealPlanBulkStatusRequest request,
            @RequestParam(defaultValue = "en") String lang) {
        return planner.updateStatusBulk(userId(jwt), request.planIds(), request.status(), lang);
    }

    @PostMapping("/bulk/delete")
    public ResponseEntity<Void> removeBulk(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody MealPlanBulkDeleteRequest request) {
        planner.removeBulk(userId(jwt), request.planIds());
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/{id}")
    public MealPlanResponse update(@AuthenticationPrincipal Jwt jwt, @PathVariable Integer id,
            @Valid @RequestBody MealPlanUpdateRequest request, @RequestParam(defaultValue = "en") String lang) {
        return planner.update(userId(jwt), id, request, lang);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> remove(@AuthenticationPrincipal Jwt jwt, @PathVariable Integer id) {
        planner.remove(userId(jwt), id);
        return ResponseEntity.noContent().build();
    }

    private Integer userId(Jwt jwt) {
        if (jwt == null) {
            throw new ResponseStatusException(UNAUTHORIZED, "Authentication is required.");
        }
        Number id = jwt.getClaim("userId");
        if (id == null) {
            throw new ResponseStatusException(UNAUTHORIZED, "The access token has no user ID.");
        }
        return id.intValue();
    }
}
