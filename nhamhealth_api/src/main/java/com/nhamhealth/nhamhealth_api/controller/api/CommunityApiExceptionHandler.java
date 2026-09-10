package com.nhamhealth.nhamhealth_api.controller.api;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;

/** Converts expected Community validation failures into useful API responses. */
@RestControllerAdvice(assignableTypes = CommunityApiController.class)
public class CommunityApiExceptionHandler {

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, String>> invalidRequest(IllegalArgumentException exception) {
        return ResponseEntity.badRequest().body(Map.of("message", message(exception, "Invalid request.")));
    }

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<Map<String, String>> status(ResponseStatusException exception) {
        return ResponseEntity.status(exception.getStatusCode())
                .body(Map.of("message", message(exception, "Unable to complete the request.")));
    }

    private static String message(Exception exception, String fallback) {
        String message = exception instanceof ResponseStatusException status
                ? status.getReason() : exception.getMessage();
        return message == null || message.isBlank() ? fallback : message;
    }
}
