package com.nhamhealth.nhamhealth_api.service.ai;

public interface FoodVisionProvider {
    AiFoodModelResult analyze(byte[] image, String contentType);
}
