from urllib.parse import urljoin, urlparse

import requests
from bs4 import BeautifulSoup

from .config import HEADERS, settings


def get_recipe_links(index_url: str | None = None) -> list[str]:
    """Collect unique recipe detail URLs from the recipe index page."""
    index_url = index_url or settings.recipes_index_url

    response = requests.get(
        index_url,
        headers=HEADERS,
        timeout=settings.request_timeout_seconds,
    )
    response.raise_for_status()

    soup = BeautifulSoup(response.text, "lxml")

    index_host = urlparse(index_url).netloc
    index_path = urlparse(index_url).path.rstrip("/") + "/"

    links: set[str] = set()

    for anchor in soup.find_all("a", href=True):
        absolute = urljoin(index_url, anchor["href"])
        parsed = urlparse(absolute)

        if parsed.netloc != index_host:
            continue

        path = parsed.path.rstrip("/") + "/"

        if not path.startswith(index_path):
            continue

        if path == index_path:
            continue

        # Avoid query/fragment duplicates.
        clean = f"{parsed.scheme}://{parsed.netloc}{parsed.path}"
        if not clean.endswith("/"):
            clean += "/"

        links.add(clean)

    return sorted(links)
