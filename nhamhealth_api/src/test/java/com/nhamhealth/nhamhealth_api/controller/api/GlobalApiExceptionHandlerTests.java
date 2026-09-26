package com.nhamhealth.nhamhealth_api.controller.api;

import java.util.NoSuchElementException;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.core.MethodParameter;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.server.ResponseStatusException;

import com.nhamhealth.nhamhealth_api.dto.response.ApiErrorResponse;

class GlobalApiExceptionHandlerTests {

    private GlobalApiExceptionHandler handler;

    @BeforeEach
    void setUp() {
        handler = new GlobalApiExceptionHandler();
    }

    @Test
    void handleValidationException_returnsBadRequestWithFieldErrors() {
        MethodParameter parameter = mock(MethodParameter.class);
        BindingResult bindingResult = mock(BindingResult.class);
        FieldError fieldError = new FieldError("userDto", "email", "Must be a valid email");
        when(bindingResult.getFieldErrors()).thenReturn(java.util.List.of(fieldError));

        MethodArgumentNotValidException exception = new MethodArgumentNotValidException(parameter, bindingResult);
        ResponseEntity<ApiErrorResponse> response = handler.handleValidationException(exception);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().status()).isEqualTo(400);
        assertThat(response.getBody().message()).isEqualTo("Must be a valid email");
        assertThat(response.getBody().errors()).containsEntry("email", "Must be a valid email");
    }

    @Test
    void handleIllegalArgument_returnsBadRequestWithMessage() {
        IllegalArgumentException exception = new IllegalArgumentException("User ID is invalid");
        ResponseEntity<ApiErrorResponse> response = handler.handleIllegalArgument(exception);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().status()).isEqualTo(400);
        assertThat(response.getBody().message()).isEqualTo("User ID is invalid");
    }

    @Test
    void handleNoSuchElement_returnsNotFound() {
        NoSuchElementException exception = new NoSuchElementException("Meal not found");
        ResponseEntity<ApiErrorResponse> response = handler.handleNoSuchElement(exception);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().status()).isEqualTo(404);
        assertThat(response.getBody().message()).isEqualTo("Meal not found");
    }

    @Test
    void handleResponseStatus_preservesStatusCodeAndReason() {
        ResponseStatusException exception = new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Token expired");
        ResponseEntity<ApiErrorResponse> response = handler.handleResponseStatus(exception);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().status()).isEqualTo(401);
        assertThat(response.getBody().message()).isEqualTo("Token expired");
    }

    @Test
    void handleAccessDenied_returnsForbidden() {
        AccessDeniedException exception = new AccessDeniedException("Access denied");
        ResponseEntity<ApiErrorResponse> response = handler.handleAccessDenied(exception);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().status()).isEqualTo(403);
        assertThat(response.getBody().message()).isEqualTo("You do not have permission to access this resource.");
    }

    @Test
    void handleGeneralException_returnsInternalServerErrorWithoutLeakingDetails() {
        RuntimeException exception = new NullPointerException("Null reference inside internal service");
        ResponseEntity<ApiErrorResponse> response = handler.handleGeneralException(exception);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.INTERNAL_SERVER_ERROR);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().status()).isEqualTo(500);
        assertThat(response.getBody().message()).isEqualTo("An unexpected internal error occurred. Please try again later.");
    }
}
