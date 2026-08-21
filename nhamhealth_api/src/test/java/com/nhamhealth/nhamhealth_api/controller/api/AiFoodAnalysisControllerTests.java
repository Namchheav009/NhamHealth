package com.nhamhealth.nhamhealth_api.controller.api;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.server.ResponseStatusException;

import com.nhamhealth.nhamhealth_api.service.AiFoodAnalysisService;

class AiFoodAnalysisControllerTests {

    @Test
    void acceptsJpegBytesWhenMultipartContentTypeIsOctetStream() throws Exception {
        AiFoodAnalysisService service = mock(AiFoodAnalysisService.class);
        AiFoodAnalysisController controller = new AiFoodAnalysisController(service);
        Jwt jwt = mock(Jwt.class);
        when(jwt.getClaim("userId")).thenReturn(7);
        byte[] jpeg = {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF, (byte) 0xE0, 0x00};
        MockMultipartFile image = new MockMultipartFile(
                "image", "food.jpg", "application/octet-stream", jpeg);

        assertNull(controller.analyze(jwt, image));

        verify(service).analyzeAndSave(eq(7), eq("food.jpg"), eq(jpeg), eq("image/jpeg"));
    }

    @Test
    void rejectsNonImageBytesEvenWhenHeaderClaimsImage() {
        AiFoodAnalysisService service = mock(AiFoodAnalysisService.class);
        AiFoodAnalysisController controller = new AiFoodAnalysisController(service);
        Jwt jwt = mock(Jwt.class);
        MockMultipartFile image = new MockMultipartFile(
                "image", "fake.jpg", "image/jpeg", new byte[] {1, 2, 3, 4});

        ResponseStatusException error = assertThrows(
                ResponseStatusException.class, () -> controller.analyze(jwt, image));

        assertEquals(400, error.getStatusCode().value());
    }

    @Test
    void rejectsInlineImagesOverNvidiaLimitBeforeCallingProvider() {
        AiFoodAnalysisService service = mock(AiFoodAnalysisService.class);
        AiFoodAnalysisController controller = new AiFoodAnalysisController(service);
        Jwt jwt = mock(Jwt.class);
        byte[] jpeg = new byte[180 * 1024 + 1];
        jpeg[0] = (byte) 0xFF;
        jpeg[1] = (byte) 0xD8;
        jpeg[2] = (byte) 0xFF;
        MockMultipartFile image = new MockMultipartFile(
                "image", "large.jpg", "image/jpeg", jpeg);

        ResponseStatusException error = assertThrows(
                ResponseStatusException.class, () -> controller.analyze(jwt, image));

        assertEquals(413, error.getStatusCode().value());
    }
}
