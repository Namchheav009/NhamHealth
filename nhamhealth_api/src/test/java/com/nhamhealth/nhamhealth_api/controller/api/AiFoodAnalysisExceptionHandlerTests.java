package com.nhamhealth.nhamhealth_api.controller.api;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.http.HttpStatus.SERVICE_UNAVAILABLE;

import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;

class AiFoodAnalysisExceptionHandlerTests {

    @Test
    void returnsTheSafeProviderReasonToTheMobileClient() {
        var response = new AiFoodAnalysisExceptionHandler().handle(
                new ResponseStatusException(
                        SERVICE_UNAVAILABLE,
                        "The food recognition provider is not configured on the API server."));

        assertEquals(SERVICE_UNAVAILABLE, response.getStatusCode());
        assertEquals(
                "The food recognition provider is not configured on the API server.",
                response.getBody().get("message"));
    }
}
