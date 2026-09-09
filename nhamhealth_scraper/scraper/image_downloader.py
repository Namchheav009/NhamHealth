import io
import re
from pathlib import Path
from urllib.parse import urlparse

import requests
from PIL import Image

from .config import HEADERS, settings


def slugify(value: str) -> str:
    value = value.lower().strip()
    value = re.sub(r"[^a-z0-9]+", "-", value)
    return value.strip("-") or "meal"


def _rasterize_svg(svg_bytes: bytes) -> bytes:
    raise ValueError(
        "The source image is SVG artwork, not a verified meal photograph. "
        "Provide a real JPG/PNG/WebP photo using --image-file."
    )


def prepare_local_image(image_path: str, meal_name: str) -> str:
    path = Path(image_path)
    if path.suffix.lower() not in {".jpg", ".jpeg", ".png", ".webp"}:
        raise ValueError("Choose a JPG, PNG or WebP meal photograph.")
    output = Path("images") / f"{slugify(meal_name)}.webp"
    output.parent.mkdir(parents=True, exist_ok=True)
    return str(_to_webp(path.read_bytes(), output, settings.max_image_bytes))


def _to_webp(image_bytes: bytes, output_path: Path, max_bytes: int) -> Path:
    image = Image.open(io.BytesIO(image_bytes))

    if image.mode not in ("RGB", "RGBA"):
        image = image.convert("RGB")

    # Avoid giant source images.
    max_dimension = 1600
    image.thumbnail((max_dimension, max_dimension))

    quality = 88

    while quality >= 55:
        buffer = io.BytesIO()
        image.save(buffer, format="WEBP", quality=quality, method=6)

        data = buffer.getvalue()

        if len(data) <= max_bytes:
            output_path.write_bytes(data)
            return output_path

        quality -= 8

    raise ValueError(
        f"Could not compress image below {max_bytes} bytes."
    )


def download_and_prepare_image(
    image_url: str | None,
    meal_name: str,
    output_dir: str | Path = "images",
) -> str | None:
    """
    Downloads the source meal image and converts it to WebP.

    This matches the Admin Add Meal form, which accepts JPG/PNG/WebP
    with a maximum size of 5 MB.

    SVG sources require a replacement meal photograph.
    """
    if not image_url:
        return None

    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    response = requests.get(
        image_url,
        headers=HEADERS,
        timeout=settings.request_timeout_seconds,
    )
    response.raise_for_status()

    content = response.content
    content_type = (response.headers.get("content-type") or "").lower()
    extension = Path(urlparse(image_url).path).suffix.lower()

    if "svg" in content_type or extension == ".svg":
        content = _rasterize_svg(content)

    output_path = output_dir / f"{slugify(meal_name)}.webp"

    return str(
        _to_webp(
            content,
            output_path,
            settings.max_image_bytes,
        )
    )
