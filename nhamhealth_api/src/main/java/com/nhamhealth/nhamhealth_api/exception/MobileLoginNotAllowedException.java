package com.nhamhealth.nhamhealth_api.exception;

public class MobileLoginNotAllowedException extends RuntimeException {

    public MobileLoginNotAllowedException() {
        super("This account must sign in through the administration portal");
    }
}
