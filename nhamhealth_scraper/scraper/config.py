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
    spring_admin_email: str = os.getenv("SPRING_ADMIN_EMAIL", "")
    spring_admin_password: str = os.getenv("SPRING_ADMIN_PASSWORD", "")
    request_delay_seconds: float = float(os.getenv("REQUEST_DELAY_SECONDS", "2"))
    request_timeout_seconds: int = int(os.getenv("REQUEST_TIMEOUT_SECONDS", "25"))
    max_image_bytes: int = int(os.getenv("MAX_IMAGE_BYTES", "5242880"))
    max_recipes: int = int(os.getenv("MAX_RECIPES", "5"))
    gemini_api_key: str = os.getenv("GEMINI_API_KEY", "")
    gemini_model: str = os.getenv("GEMINI_MODEL", "gemini-3.5-flash-lite")
    gemini_base_url: str = os.getenv("GEMINI_BASE_URL", "https://generativelanguage.googleapis.com/v1beta")


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
