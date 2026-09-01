package com.nhamhealth.nhamhealth_api.controller.api;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;

/** Returns safe, actionable AI food errors to the mobile client. */
@RestControllerAdvice(assignableTypes = AiFoodAnalysisController.class)
public class AiFoodAnalysisExceptionHandler {

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<Map<String, Object>> handle(ResponseStatusException error) {
        String message = error.getReason();
        if (message == null || message.isBlank()) {
            message = "Food analysis is temporarily unavailable.";
        }
        return ResponseEntity.status(error.getStatusCode()).body(Map.of(
                "status", error.getStatusCode().value(),
                "message", message));
    }
}
