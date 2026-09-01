package com.nhamhealth.nhamhealth_api.service.user;

import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

import javax.imageio.ImageIO;
import javax.imageio.ImageReader;
import javax.imageio.stream.ImageInputStream;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
public class ProfileImageStorageService {

    private static final long MAX_IMAGE_SIZE_BYTES = 5 * 1024 * 1024;
    private static final long MAX_DECODED_IMAGE_PIXELS = 25_000_000;
    private static final Map<String, String> EXTENSIONS = Map.of(
            "image/jpeg", "jpg",
            "image/jpg", "jpg",
            "image/pjpeg", "jpg",
            "image/png", "png",
            "image/webp", "webp");
    private static final Map<String, String> CONTENT_TYPES = Map.of(
            "jpg", "image/jpeg",
            "png", "image/png",
            "webp", "image/webp");

    private final Path profileImageDirectory;
    private final Path mealImageDirectory;
    private final Path recipeStepImageDirectory;
    private final Path ingredientImageDirectory;
    private final Path postImageDirectory;
    private final String supabaseUrl;
    private final String supabaseServiceKey;
    private final String supabaseBucket;
    private final HttpClient httpClient;

    @Autowired
    public ProfileImageStorageService(
            @Value("${app.upload.directory:uploads}") String uploadDirectory,
            @Value("${app.storage.supabase.url:}") String supabaseUrl,
            @Value("${app.storage.supabase.service-key:}") String supabaseServiceKey,
            @Value("${app.storage.supabase.bucket:nhamhealth-images}") String supabaseBucket) {
        this(
                uploadDirectory,
                supabaseUrl,
                supabaseServiceKey,
                supabaseBucket,
                HttpClient.newBuilder()
                        .connectTimeout(Duration.ofSeconds(10))
                        .build());
    }

    ProfileImageStorageService(
            String uploadDirectory,
            String supabaseUrl,
            String supabaseServiceKey,
            String supabaseBucket,
            HttpClient httpClient) {
        this.profileImageDirectory = Path.of(uploadDirectory)
                .toAbsolutePath()
                .normalize()
                .resolve("profile-images");
        this.mealImageDirectory = Path.of(uploadDirectory)
                .toAbsolutePath()
                .normalize()
                .resolve("meal-images");
        this.recipeStepImageDirectory = Path.of(uploadDirectory)
                .toAbsolutePath()
                .normalize()
                .resolve("recipe-step-images");
        this.ingredientImageDirectory = Path.of(uploadDirectory)
                .toAbsolutePath()
                .normalize()
                .resolve("ingredient-images");
        this.postImageDirectory = Path.of(uploadDirectory)
                .toAbsolutePath()
                .normalize()
                .resolve("post-images");
        this.supabaseUrl = stripTrailingSlash(supabaseUrl);
        this.supabaseServiceKey = supabaseServiceKey == null ? "" : supabaseServiceKey.trim();
        this.supabaseBucket = supabaseBucket == null ? "nhamhealth-images" : supabaseBucket.trim();
        this.httpClient = httpClient;
    }

    public String storeProfileImage(MultipartFile file) {
        return storeImage(file, profileImageDirectory, "/uploads/profile-images/", "Profile");
    }

    public String storeMealImage(MultipartFile file) {
        return storeImage(file, mealImageDirectory, "/uploads/meal-images/", "Meal");
    }

    public String storeRecipeStepImage(MultipartFile file) {
        return storeImage(file, recipeStepImageDirectory, "/uploads/recipe-step-images/", "Recipe step");
    }

    public String storeIngredientImage(MultipartFile file) {
        return storeImage(file, ingredientImageDirectory, "/uploads/ingredient-images/", "Ingredient");
    }

    public String storePostImage(MultipartFile file) {
        return storeImage(file, postImageDirectory, "/uploads/post-images/", "Post");
    }

    public boolean isStoredMealImageUrl(String imageUrl) {
        return isStoredImageUrl(imageUrl, "/uploads/meal-images/", "meal-images");
    }

    public String mealThumbnailUrl(String imageUrl) {
        if (imageUrl == null || imageUrl.isBlank()) {
            return imageUrl;
        }
        String normalizedUrl = imageUrl.trim();
        String publicPrefix = supabaseUrl + "/storage/v1/object/public/" + supabaseBucket + "/";
        if (!usesSupabaseStorage() || !normalizedUrl.startsWith(publicPrefix)) {
            return normalizedUrl;
        }
        String objectPath = normalizedUrl.substring(publicPrefix.length());
        return supabaseUrl + "/storage/v1/render/image/public/" + supabaseBucket + "/"
                + objectPath + "?width=300&height=300&resize=cover&quality=75&format=webp";
    }

    public boolean isStoredRecipeStepImageUrl(String imageUrl) {
        return isStoredImageUrl(imageUrl, "/uploads/recipe-step-images/", "recipe-step-images");
    }

    private String storeImage(MultipartFile file, Path imageDirectory, String publicPath, String imageLabel) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("Please choose an image file");
        }
        if (file.getSize() > MAX_IMAGE_SIZE_BYTES) {
            throw new IllegalArgumentException(imageLabel + " images must be 5 MB or smaller");
        }

        try {
            byte[] imageBytes = file.getBytes();
            ImageFormat imageFormat = detectImageFormat(imageBytes, file.getContentType(), imageLabel);
            String filename = UUID.randomUUID() + "." + imageFormat.extension();
            if (usesSupabaseStorage()) {
                return storeInSupabase(
                        imageBytes,
                        imageDirectory.getFileName().toString(),
                        filename,
                        imageFormat.contentType(),
                        imageLabel);
            }

            Files.createDirectories(imageDirectory);
            Files.write(imageDirectory.resolve(filename), imageBytes);
            return publicPath + filename;
        } catch (IOException exception) {
            throw new IllegalStateException("Unable to store the " + imageLabel.toLowerCase() + " image", exception);
        }
    }

    private ImageFormat detectImageFormat(byte[] imageBytes, String declaredContentType, String imageLabel) {
        String extension;
        if (isJpeg(imageBytes)) {
            extension = "jpg";
        } else if (isPng(imageBytes)) {
            extension = "png";
        } else if (isWebp(imageBytes)) {
            extension = "webp";
        } else {
            throw unsupportedImage(imageLabel);
        }

        String normalizedContentType = normalizeContentType(declaredContentType);
        String declaredExtension = EXTENSIONS.get(normalizedContentType);
        boolean genericContentType = normalizedContentType.isBlank()
                || "application/octet-stream".equals(normalizedContentType);
        if (!genericContentType && (declaredExtension == null || !declaredExtension.equals(extension))) {
            throw unsupportedImage(imageLabel);
        }
        if (!"webp".equals(extension) && !isDecodableRasterImage(imageBytes)) {
            throw unsupportedImage(imageLabel);
        }

        return new ImageFormat(extension, CONTENT_TYPES.get(extension));
    }

    private IllegalArgumentException unsupportedImage(String imageLabel) {
        return new IllegalArgumentException(
                imageLabel + " image must be a valid JPG, PNG, or WebP file");
    }

    private String normalizeContentType(String contentType) {
        if (contentType == null) {
            return "";
        }
        int parameters = contentType.indexOf(';');
        String value = parameters >= 0 ? contentType.substring(0, parameters) : contentType;
        return value.trim().toLowerCase(Locale.ROOT);
    }

    private boolean isJpeg(byte[] bytes) {
        return bytes.length >= 3
                && unsigned(bytes[0]) == 0xFF
                && unsigned(bytes[1]) == 0xD8
                && unsigned(bytes[2]) == 0xFF;
    }

    private boolean isPng(byte[] bytes) {
        int[] signature = { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A };
        if (bytes.length < signature.length) {
            return false;
        }
        for (int index = 0; index < signature.length; index++) {
            if (unsigned(bytes[index]) != signature[index]) {
                return false;
            }
        }
        return true;
    }

    private boolean isWebp(byte[] bytes) {
        if (bytes.length < 30
                || bytes[0] != 'R'
                || bytes[1] != 'I'
                || bytes[2] != 'F'
                || bytes[3] != 'F'
                || bytes[8] != 'W'
                || bytes[9] != 'E'
                || bytes[10] != 'B'
                || bytes[11] != 'P'
                || littleEndianUnsignedInt(bytes, 4) + 8 != bytes.length) {
            return false;
        }

        boolean hasImagePayload = false;
        boolean hasSafeDimensions = false;
        int offset = 12;
        while (offset + 8 <= bytes.length) {
            long chunkSize = littleEndianUnsignedInt(bytes, offset + 4);
            long nextOffset = (long) offset + 8 + chunkSize + (chunkSize & 1);
            if (nextOffset > bytes.length) {
                return false;
            }

            if (matchesFourCc(bytes, offset, "VP8 ")) {
                if (chunkSize < 10 || offset + 18 > bytes.length
                        || unsigned(bytes[offset + 11]) != 0x9D
                        || unsigned(bytes[offset + 12]) != 0x01
                        || unsigned(bytes[offset + 13]) != 0x2A) {
                    return false;
                }
                int width = littleEndianUnsignedShort(bytes, offset + 14) & 0x3FFF;
                int height = littleEndianUnsignedShort(bytes, offset + 16) & 0x3FFF;
                hasImagePayload = true;
                hasSafeDimensions = hasSafeDimensions(width, height);
            } else if (matchesFourCc(bytes, offset, "VP8L")) {
                if (chunkSize < 5 || offset + 13 > bytes.length
                        || unsigned(bytes[offset + 8]) != 0x2F) {
                    return false;
                }
                int width = 1 + unsigned(bytes[offset + 9])
                        + ((unsigned(bytes[offset + 10]) & 0x3F) << 8);
                int height = 1 + ((unsigned(bytes[offset + 10]) & 0xC0) >> 6)
                        + (unsigned(bytes[offset + 11]) << 2)
                        + ((unsigned(bytes[offset + 12]) & 0x0F) << 10);
                hasImagePayload = true;
                hasSafeDimensions = hasSafeDimensions(width, height);
            } else if (matchesFourCc(bytes, offset, "VP8X")) {
                if (chunkSize < 10 || offset + 18 > bytes.length) {
                    return false;
                }
                int width = 1 + littleEndianUnsigned24(bytes, offset + 12);
                int height = 1 + littleEndianUnsigned24(bytes, offset + 15);
                hasSafeDimensions = hasSafeDimensions(width, height);
            } else if (matchesFourCc(bytes, offset, "ANMF")) {
                hasImagePayload = chunkSize > 16;
            }
            offset = (int) nextOffset;
        }
        return offset == bytes.length && hasImagePayload && hasSafeDimensions;
    }

    private boolean isDecodableRasterImage(byte[] bytes) {
        try (ByteArrayInputStream byteStream = new ByteArrayInputStream(bytes);
                ImageInputStream imageStream = ImageIO.createImageInputStream(byteStream)) {
            if (imageStream == null) {
                return false;
            }
            var readers = ImageIO.getImageReaders(imageStream);
            if (!readers.hasNext()) {
                return false;
            }
            ImageReader reader = readers.next();
            try {
                reader.setInput(imageStream, true, true);
                int width = reader.getWidth(0);
                int height = reader.getHeight(0);
                if (!hasSafeDimensions(width, height)) {
                    return false;
                }
                BufferedImage decodedImage = reader.read(0);
                return decodedImage != null;
            } finally {
                reader.dispose();
            }
        } catch (IOException | RuntimeException exception) {
            return false;
        }
    }

    private boolean hasSafeDimensions(int width, int height) {
        return width > 0
                && height > 0
                && (long) width * height <= MAX_DECODED_IMAGE_PIXELS;
    }

    private boolean matchesFourCc(byte[] bytes, int offset, String value) {
        return bytes[offset] == value.charAt(0)
                && bytes[offset + 1] == value.charAt(1)
                && bytes[offset + 2] == value.charAt(2)
                && bytes[offset + 3] == value.charAt(3);
    }

    private int littleEndianUnsignedShort(byte[] bytes, int offset) {
        return unsigned(bytes[offset]) | (unsigned(bytes[offset + 1]) << 8);
    }

    private int littleEndianUnsigned24(byte[] bytes, int offset) {
        return unsigned(bytes[offset])
                | (unsigned(bytes[offset + 1]) << 8)
                | (unsigned(bytes[offset + 2]) << 16);
    }

    private long littleEndianUnsignedInt(byte[] bytes, int offset) {
        return Integer.toUnsignedLong(unsigned(bytes[offset])
                | (unsigned(bytes[offset + 1]) << 8)
                | (unsigned(bytes[offset + 2]) << 16)
                | (unsigned(bytes[offset + 3]) << 24));
    }

    private int unsigned(byte value) {
        return value & 0xFF;
    }

    private boolean usesSupabaseStorage() {
        return !supabaseUrl.isBlank() && !supabaseServiceKey.isBlank() && !supabaseBucket.isBlank();
    }

    private boolean isStoredImageUrl(String imageUrl, String localPathPrefix, String storageFolder) {
        if (imageUrl == null || imageUrl.isBlank()) {
            return false;
        }

        String normalizedUrl = imageUrl.trim();
        if (normalizedUrl.startsWith(localPathPrefix)) {
            return true;
        }

        String sharedStoragePrefix = supabaseUrl + "/storage/v1/object/public/"
                + supabaseBucket + "/" + storageFolder + "/";
        return usesSupabaseStorage() && normalizedUrl.startsWith(sharedStoragePrefix);
    }

    private String storeInSupabase(
            byte[] imageBytes,
            String folder,
            String filename,
            String contentType,
            String imageLabel) throws IOException {
        String objectPath = folder + "/" + filename;
        URI uploadUri = URI.create(supabaseUrl + "/storage/v1/object/" + supabaseBucket + "/" + objectPath);
        HttpRequest.Builder requestBuilder = HttpRequest.newBuilder(uploadUri)
                .timeout(Duration.ofSeconds(30))
                .header("apikey", supabaseServiceKey)
                .header("Content-Type", contentType)
                .POST(HttpRequest.BodyPublishers.ofByteArray(imageBytes));

        // New sb_secret_ keys are sent with apikey only. Legacy service_role
        // JWT keys also need the Bearer header for Storage authorization.
        if (!supabaseServiceKey.startsWith("sb_secret_")) {
            requestBuilder.header("Authorization", "Bearer " + supabaseServiceKey);
        }
        HttpRequest request = requestBuilder.build();

        try {
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                throw new IllegalStateException("Unable to store the " + imageLabel.toLowerCase()
                        + " image in shared storage (HTTP " + response.statusCode() + ")");
            }
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Image upload was interrupted", exception);
        }

        return supabaseUrl + "/storage/v1/object/public/" + supabaseBucket + "/" + objectPath;
    }

    private String stripTrailingSlash(String value) {
        if (value == null) {
            return "";
        }
        String normalized = value.trim();
        while (normalized.endsWith("/")) {
            normalized = normalized.substring(0, normalized.length() - 1);
        }
        return normalized;
    }

    private record ImageFormat(String extension, String contentType) {
    }
}
