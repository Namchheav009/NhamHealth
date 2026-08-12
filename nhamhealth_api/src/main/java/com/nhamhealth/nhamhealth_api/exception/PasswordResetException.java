package com.nhamhealth.nhamhealth_api.exception;

import org.springframework.http.HttpStatus;

public class PasswordResetException extends RuntimeException {

    private final HttpStatus status;

    public PasswordResetException(HttpStatus status, String message) {
        super(message);
        this.status = status;
    }

    public HttpStatus getStatus() {
        return status;
    }
}
