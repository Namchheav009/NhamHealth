package com.nhamhealth.nhamhealth_api.dto.response;

import java.util.Map;

public record ApiErrorResponse(
        int status,
        String error,
        String message,
        Map<String, String> errors) {

    public ApiErrorResponse(int status, String error, String message) {
        this(status, error, message, Map.of());
    }

    public ApiErrorResponse {
        errors = errors == null ? Map.of() : Map.copyOf(errors);
    }
}
