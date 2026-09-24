package com.nhamhealth.nhamhealth_api.controller.api;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;

/** Returns the planner's actionable validation reason to mobile clients. */
@RestControllerAdvice(assignableTypes = WeeklyMealPlannerApiController.class)
public class WeeklyMealPlannerApiExceptionHandler {

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<Map<String, Object>> handle(ResponseStatusException error) {
        String message = error.getReason();
        if (message == null || message.isBlank()) {
            message = "Unable to complete the meal-planner request.";
        }
        return ResponseEntity.status(error.getStatusCode()).body(Map.of(
                "status", error.getStatusCode().value(),
                "message", message));
    }
}
