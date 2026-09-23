import os
from dataclasses import dataclass
from dotenv import load_dotenv

load_dotenv()


@dataclass(frozen=True)
class Settings:
    recipes_index_url: str = os.getenv(
        "RECIPES_INDEX_URL",
        "https://cambodiancookbook.com/recipes/",
    )
    spring_import_url: str = os.getenv(
        "SPRING_IMPORT_URL",
        "http://localhost:8080/api/admin/meals/import-scraped",
    )
    spring_import_token: str = os.getenv("SPRING_IMPORT_TOKEN", "")
    spring_admin_login_url: str = os.getenv(
        "SPRING_ADMIN_LOGIN_URL",
        "http://localhost:8080/api/admin/auth/login",
    )
    spring_ingredient_image_upload_url: str = os.getenv(
        "SPRING_INGREDIENT_IMAGE_UPLOAD_URL",
        "http://localhost:8080/api/admin/ingredient-images",
    )
    spring_admin_email: str = os.getenv("SPRING_ADMIN_EMAIL", "")
    spring_admin_password: str = os.getenv("SPRING_ADMIN_PASSWORD", "")
    request_delay_seconds: float = float(os.getenv("REQUEST_DELAY_SECONDS", "15"))
    request_timeout_seconds: int = int(os.getenv("REQUEST_TIMEOUT_SECONDS", "25"))
    max_image_bytes: int = int(os.getenv("MAX_IMAGE_BYTES", "5242880"))
    max_recipes: int = int(os.getenv("MAX_RECIPES", "5"))
    gemini_api_key: str = os.getenv("GEMINI_API_KEY", "")
    # Primary: Flash Lite, Fallback: Flash (conditional)
    gemini_model: str = os.getenv("GEMINI_MODEL", "gemini-3.1-flash-lite")
    gemini_fallback_model: str = os.getenv("GEMINI_FALLBACK_MODEL", "gemini-3.6-flash")
    ai_fallback_confidence: float = float(os.getenv("AI_FALLBACK_CONFIDENCE", "0.75"))
    gemini_base_url: str = os.getenv("GEMINI_BASE_URL", "https://generativelanguage.googleapis.com/v1beta")
    glossary_version: str = os.getenv("GLOSSARY_VERSION", "2.0")
    # One structured AI request per recipe. Review is safer and cheaper than
    # repeatedly asking the model to regenerate the same translation.
    max_qa_retries: int = int(os.getenv("MAX_QA_RETRIES", "0"))
    max_ai_requests: int | None = int(os.getenv("MAX_AI_REQUESTS")) if os.getenv("MAX_AI_REQUESTS") else None
    trusted_image_dir: str = os.getenv("TRUSTED_IMAGE_DIR", "images/ingredients_library")
    staging_file: str = os.getenv("STAGING_FILE", "output/staging_recipes.json")
    themealdb_api_key: str = os.getenv("THEMEALDB_API_KEY", "1")
    ingredient_images_dir: str = os.getenv("INGREDIENT_IMAGES_DIR", "images/ingredients")
    ingredient_image_cache_file: str = os.getenv("INGREDIENT_IMAGE_CACHE_FILE", "output/ingredient_image_cache.json")
    ingredient_ai_cache_file: str = os.getenv("INGREDIENT_AI_CACHE_FILE", "output/ingredient_ai_cache.json")
    image_search_enabled: bool = os.getenv("IMAGE_SEARCH_ENABLED", "true").lower() == "true"
    image_search_provider: str = os.getenv("IMAGE_SEARCH_PROVIDER", "wikimedia")
    ingredient_ai_image_validation: bool = os.getenv("INGREDIENT_AI_IMAGE_VALIDATION", "true").lower() == "true"
    ingredient_image_min_confidence: float = float(os.getenv("INGREDIENT_IMAGE_MIN_CONFIDENCE", "0.80"))
    spring_missing_ingredient_images_url: str = os.getenv("SPRING_MISSING_INGREDIENT_IMAGES_URL", "http://localhost:8080/api/admin/ingredients/missing-images")
    ingredient_translation_ai_enabled: bool = os.getenv("INGREDIENT_TRANSLATION_AI_ENABLED", "false").lower() == "true"


settings = Settings()


HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/152.0 Safari/537.36 "
        "NhamHealthRecipeImporter/1.0"
    ),
    "Accept-Language": "en-US,en;q=0.9",
}
