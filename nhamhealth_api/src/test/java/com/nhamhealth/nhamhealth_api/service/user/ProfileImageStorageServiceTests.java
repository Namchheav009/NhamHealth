package com.nhamhealth.nhamhealth_api.service.user;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Comparator;

import javax.imageio.ImageIO;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;

class ProfileImageStorageServiceTests {

    private static final String SUPABASE_URL = "https://example-project.supabase.co";
    private static final String BUCKET = "nhamhealth-images";

    private final ProfileImageStorageService storageService = new ProfileImageStorageService(
            "uploads", SUPABASE_URL, "sb_secret_test", BUCKET);
    private Path testUploadDirectory;

    @BeforeEach
    void createTestUploadDirectory() throws IOException {
        Path testRoot = Path.of("target", "test-uploads");
        Files.createDirectories(testRoot);
        testUploadDirectory = Files.createTempDirectory(testRoot, "profile-image-");
    }

    @AfterEach
    void removeTestUploadDirectory() throws IOException {
        try (var paths = Files.walk(testUploadDirectory)) {
            for (Path path : paths.sorted(Comparator.reverseOrder()).toList()) {
                Files.deleteIfExists(path);
            }
        }
    }

    @Test
    void acceptsLocalAndConfiguredSupabaseMealImageUrls() {
        assertTrue(storageService.isStoredMealImageUrl("/uploads/meal-images/local-image.png"));
        assertTrue(storageService.isStoredMealImageUrl(
                SUPABASE_URL + "/storage/v1/object/public/" + BUCKET + "/meal-images/shared-image.png"));
        assertFalse(storageService.isStoredMealImageUrl(
                "https://untrusted.example/meal-images/shared-image.png"));
    }

    @Test
    void acceptsOnlyTheMatchingRecipeStepStorageFolder() {
        assertTrue(storageService.isStoredRecipeStepImageUrl(
                SUPABASE_URL + "/storage/v1/object/public/" + BUCKET + "/recipe-step-images/shared-step.png"));
        assertFalse(storageService.isStoredRecipeStepImageUrl(
                SUPABASE_URL + "/storage/v1/object/public/" + BUCKET + "/meal-images/shared-image.png"));
    }

    @Test
    void acceptsARealJpegWhenMultipartUsesTheGenericContentType() {
        ProfileImageStorageService localStorage = new ProfileImageStorageService(
                testUploadDirectory.toString(), "", "", BUCKET);
        MockMultipartFile image = new MockMultipartFile(
                "file",
                "picker-image.jpg",
                MediaType.APPLICATION_OCTET_STREAM_VALUE,
                jpegBytes());

        String imageUrl = localStorage.storeProfileImage(image);

        assertTrue(imageUrl.startsWith("/uploads/profile-images/"));
        assertTrue(imageUrl.endsWith(".jpg"));
        assertTrue(Files.exists(testUploadDirectory
                .resolve("profile-images")
                .resolve(imageUrl.substring(imageUrl.lastIndexOf('/') + 1))));
    }

    @Test
    void rejectsContentThatIsNotARealSupportedImage() {
        ProfileImageStorageService localStorage = new ProfileImageStorageService(
                testUploadDirectory.toString(), "", "", BUCKET);
        MockMultipartFile image = new MockMultipartFile(
                "file",
                "fake.jpg",
                MediaType.IMAGE_JPEG_VALUE,
                new byte[] {
                        (byte) 0xFF, (byte) 0xD8, (byte) 0xFF, (byte) 0xE0,
                        0x00, 0x10, 0x4A, 0x46, 0x49, 0x46
                });

        assertThrows(IllegalArgumentException.class, () -> localStorage.storeProfileImage(image));
    }

    @Test
    void sendsCanonicalImageMetadataToSupabaseStorage() throws Exception {
        HttpClient httpClient = mock(HttpClient.class);
        @SuppressWarnings("unchecked")
        HttpResponse<Void> response = mock(HttpResponse.class);
        when(response.statusCode()).thenReturn(200);
        when(httpClient.send(
                any(HttpRequest.class),
                org.mockito.ArgumentMatchers.<HttpResponse.BodyHandler<Void>>any()))
                .thenReturn(response);
        ProfileImageStorageService supabaseStorage = new ProfileImageStorageService(
                testUploadDirectory.toString(), SUPABASE_URL, "sb_secret_test", BUCKET, httpClient);
        MockMultipartFile image = new MockMultipartFile(
                "file",
                "picker-image.bin",
                MediaType.APPLICATION_OCTET_STREAM_VALUE,
                jpegBytes());

        String imageUrl = supabaseStorage.storeProfileImage(image);

        ArgumentCaptor<HttpRequest> requestCaptor = ArgumentCaptor.forClass(HttpRequest.class);
        verify(httpClient).send(
                requestCaptor.capture(),
                org.mockito.ArgumentMatchers.<HttpResponse.BodyHandler<Void>>any());
        HttpRequest request = requestCaptor.getValue();
        assertTrue(request.uri().getPath().matches(
                "/storage/v1/object/" + BUCKET + "/profile-images/[0-9a-f-]+\\.jpg"));
        assertEquals("image/jpeg", request.headers().firstValue("Content-Type").orElseThrow());
        assertEquals("sb_secret_test", request.headers().firstValue("apikey").orElseThrow());
        assertFalse(request.headers().firstValue("Authorization").isPresent());
        assertTrue(request.bodyPublisher().orElseThrow().contentLength() > 0);
        assertTrue(imageUrl.matches(
                SUPABASE_URL + "/storage/v1/object/public/" + BUCKET
                        + "/profile-images/[0-9a-f-]+\\.jpg"));
    }

    private byte[] jpegBytes() {
        BufferedImage image = new BufferedImage(2, 2, BufferedImage.TYPE_INT_RGB);
        try (ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            if (!ImageIO.write(image, "jpg", output)) {
                throw new IllegalStateException("No JPEG test image writer is available");
            }
            return output.toByteArray();
        } catch (IOException exception) {
            throw new IllegalStateException("Unable to create a JPEG test image", exception);
        }
    }
}
