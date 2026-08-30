package com.nhamhealth.nhamhealth_api.controller.auth;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import com.nhamhealth.nhamhealth_api.dto.response.AuthErrorResponse;
import com.nhamhealth.nhamhealth_api.exception.InvalidSessionException;
import com.nhamhealth.nhamhealth_api.exception.PasswordResetException;

@RestControllerAdvice(assignableTypes = AuthController.class)
public class AuthApiExceptionHandler {

    private static final Logger LOGGER = LoggerFactory.getLogger(AuthApiExceptionHandler.class);

    @ExceptionHandler(MethodArgumentNotValidException.class)
    ResponseEntity<AuthErrorResponse> handleValidation(MethodArgumentNotValidException exception) {
        String message = exception.getBindingResult().getFieldErrors().stream()
                .findFirst()
                .map(error -> error.getDefaultMessage())
                .orElse("The authentication request is invalid");
        return ResponseEntity.badRequest().body(new AuthErrorResponse(message));
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    ResponseEntity<AuthErrorResponse> handleUnreadableRequest() {
        return ResponseEntity.badRequest()
                .body(new AuthErrorResponse("Request body must be valid JSON"));
    }

    @ExceptionHandler(PasswordResetException.class)
    ResponseEntity<AuthErrorResponse> handlePasswordReset(PasswordResetException exception) {
        return ResponseEntity.status(exception.getStatus())
                .body(new AuthErrorResponse(exception.getMessage()));
    }

    @ExceptionHandler(InvalidSessionException.class)
    ResponseEntity<AuthErrorResponse> handleInvalidSession(InvalidSessionException exception) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(new AuthErrorResponse(exception.getMessage()));
    }

    @ExceptionHandler(DataAccessException.class)
    ResponseEntity<AuthErrorResponse> handleDatabaseFailure(DataAccessException exception) {
        LOGGER.error("Authentication database request failed", exception);
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .body(new AuthErrorResponse(
                        "The authentication service is temporarily unavailable"));
    }

    @ExceptionHandler(Exception.class)
    ResponseEntity<AuthErrorResponse> handleUnexpectedFailure(Exception exception) {
        LOGGER.error("Unexpected authentication API failure", exception);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new AuthErrorResponse("The server could not complete sign in"));
    }
}
