from datetime import datetime

class RSSCache:
    def __init__(self, ttl_seconds: int = 900):  # 15 min default
        self._cache: dict = {}
        self._timestamps: dict = {}
        self.ttl = ttl_seconds
    
    def get(self, key: str) -> list | None:
        if key not in self._cache:
            return None
        age = (datetime.utcnow() - self._timestamps[key]).total_seconds()
        if age > self.ttl:
            del self._cache[key]
            del self._timestamps[key]
            return None
        return self._cache[key]
    
    def set(self, key: str, data: list):
        self._cache[key] = data
        self._timestamps[key] = datetime.utcnow()
    
    def clear(self):
        self._cache.clear()
        self._timestamps.clear()

# Singleton instance used across the app
rss_cache = RSSCache(ttl_seconds=900)
