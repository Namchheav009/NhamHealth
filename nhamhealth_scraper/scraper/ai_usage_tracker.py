"""Centralized usage tracker and request budget limiter for Gemini AI calls."""
from __future__ import annotations
from dataclasses import dataclass
from typing import Optional


@dataclass
class AiUsageTracker:
    flash_lite_requests: int = 0
    flash_requests: int = 0
    cache_hits: int = 0
    ai_calls_avoided: int = 0
    max_ai_requests: Optional[int] = None

    @property
    def total_ai_requests(self) -> int:
        return self.flash_lite_requests + self.flash_requests

    def set_budget(self, max_requests: Optional[int]) -> None:
        self.max_ai_requests = max_requests

    def can_call_ai(self) -> bool:
        if self.max_ai_requests is not None:
            return self.total_ai_requests < self.max_ai_requests
        return True

    def is_budget_exhausted(self) -> bool:
        return not self.can_call_ai()

    def record_request(self, model_name: str) -> None:
        if "lite" in (model_name or "").lower():
            self.flash_lite_requests += 1
        else:
            self.flash_requests += 1

    def record_cache_hit(self, count: int = 1) -> None:
        self.cache_hits += count
        self.ai_calls_avoided += count

    def record_avoided(self, count: int = 1) -> None:
        self.ai_calls_avoided += count

    def reset(self) -> None:
        self.flash_lite_requests = 0
        self.flash_requests = 0
        self.cache_hits = 0
        self.ai_calls_avoided = 0

    def summary_string(self) -> str:
        lines = [
            "AI Usage Summary",
            "----------------",
            f"Flash Lite requests: {self.flash_lite_requests}",
            f"Flash requests: {self.flash_requests}",
            f"Cache hits: {self.cache_hits}",
            f"AI calls avoided: {self.ai_calls_avoided}",
        ]
        return "\n".join(lines)

    def print_summary(self) -> None:
        print(f"\n{self.summary_string()}")


# Global singleton tracker
ai_tracker = AiUsageTracker()

