package com.nhamhealth.nhamhealth_api.service;

public interface FoodVisionProvider {
    AiFoodModelResult analyze(byte[] image, String contentType);
}
