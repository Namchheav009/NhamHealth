package com.nhamhealth.nhamhealth_api.controller.api;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.LocalDateTime;

import org.junit.jupiter.api.Test;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.RequestMapping;

import com.nhamhealth.nhamhealth_api.dto.request.CreateFollowConnection;
import com.nhamhealth.nhamhealth_api.dto.response.FollowConnectionResponse;
import com.nhamhealth.nhamhealth_api.service.community.FollowConnectionRateLimitException;
import com.nhamhealth.nhamhealth_api.service.community.FollowConnectionRateLimiter;
import com.nhamhealth.nhamhealth_api.service.community.FollowConnectionService;

class FollowConnectionApiControllerTests {
    @Test
    void senderComesFromJwtAndReceiverTwoComesFromBody() {
        assertEquals("/api/follows/connections",
                FollowConnectionApiController.class.getAnnotation(RequestMapping.class).value()[0]);
        FollowConnectionService service = mock(FollowConnectionService.class);
        FollowConnectionRateLimiter limiter = mock(FollowConnectionRateLimiter.class);
        Jwt jwt = mock(Jwt.class);
        when(jwt.getClaim("userId")).thenReturn(7);
        var result = new FollowConnectionResponse(
                4, 7, 2, "PENDING", "OUTGOING_PENDING", LocalDateTime.now(), null);
        when(service.create(7, 2)).thenReturn(result);

        var response = new FollowConnectionApiController(service, limiter)
                .create(jwt, new CreateFollowConnection(2));

        assertEquals(201, response.getStatusCode().value());
        verify(limiter).check(7);
        verify(service).create(7, 2);
    }

    @Test
    void rateLimitResponseIncludesRetryAfter() {
        var response = new FollowConnectionApiExceptionHandler()
                .rateLimited(new FollowConnectionRateLimitException(17));

        assertEquals(429, response.getStatusCode().value());
        assertEquals("17", response.getHeaders().getFirst("Retry-After"));
    }
}
