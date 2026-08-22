package com.nhamhealth.nhamhealth_api.exception;

public class InvalidSessionException extends RuntimeException {

    public InvalidSessionException() {
        super("Your session is no longer valid. Please sign in again.");
    }
}
