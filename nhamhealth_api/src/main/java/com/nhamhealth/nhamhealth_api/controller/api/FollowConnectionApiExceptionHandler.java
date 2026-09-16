package com.nhamhealth.nhamhealth_api.controller.api;

import java.util.Map;

import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;

import com.nhamhealth.nhamhealth_api.service.community.FollowConnectionRateLimitException;

@RestControllerAdvice(assignableTypes = FollowConnectionApiController.class)
public class FollowConnectionApiExceptionHandler {
    @ExceptionHandler(FollowConnectionRateLimitException.class)
    ResponseEntity<Map<String, Object>> rateLimited(FollowConnectionRateLimitException exception) {
        return ResponseEntity.status(429)
                .header(HttpHeaders.RETRY_AFTER, Long.toString(exception.getRetryAfterSeconds()))
                .body(Map.of(
                        "message", exception.getMessage(),
                        "retryAfterSeconds", exception.getRetryAfterSeconds()));
    }

    @ExceptionHandler(ResponseStatusException.class)
    ResponseEntity<Map<String, String>> status(ResponseStatusException exception) {
        return ResponseEntity.status(exception.getStatusCode())
                .body(Map.of("message", message(exception.getReason(), "Unable to update this invitation.")));
    }

    @ExceptionHandler({ IllegalArgumentException.class, MethodArgumentNotValidException.class })
    ResponseEntity<Map<String, String>> invalid(Exception exception) {
        String detail = exception instanceof MethodArgumentNotValidException validation
                ? validation.getBindingResult().getAllErrors().stream().findFirst()
                        .map(error -> error.getDefaultMessage()).orElse("Invalid request.")
                : exception.getMessage();
        return ResponseEntity.badRequest().body(Map.of("message", message(detail, "Invalid request.")));
    }

    private String message(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }
}
