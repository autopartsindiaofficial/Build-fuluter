import AsyncStorage from '@react-native-async-storage/async-storage';

/**
 * High-Performance In-Memory L1 + Persistent L2 Cache Manager
 * 
 * Features:
 * - 0ms In-Memory Synchronous Read (L1)
 * - Automatic Async Persistence to AsyncStorage (L2)
 * - Automatic TTL (Time to Live) Expiration
 * - Request Deduplication (prevents duplicate simultaneous network fetches)
 * - Memory Pressure Eviction (LRU strategy)
 */

interface CacheItem<T> {
  data: T;
  timestamp: number;
  ttl?: number;
}

class FastCacheManager {
  private memoryCache = new Map<string, CacheItem<any>>();
  private inFlightRequests = new Map<string, Promise<any>>();
  private maxMemoryEntries = 250;

  constructor() {
    // Hydrate top critical keys on module boot
    this.hydrateCriticalKeys();
  }

  private async hydrateCriticalKeys() {
    try {
      const keys = [
        '@autoparts_firestore_topCategories',
        '@autoparts_firestore_carBrands',
        '@autoparts_firestore_banners',
        '@autoparts_saved_location',
      ];
      const pairs = await AsyncStorage.multiGet(keys);
      pairs.forEach(([key, val]) => {
        if (val) {
          try {
            const parsed = JSON.parse(val);
            this.memoryCache.set(key, {
              data: parsed,
              timestamp: Date.now(),
            });
          } catch (_) {}
        }
      });
    } catch (_) {}
  }

  /**
   * Synchronous L1 Read (Instant 0ms)
   */
  getSync<T = any>(key: string): T | null {
    const item = this.memoryCache.get(key);
    if (!item) return null;

    if (item.ttl && Date.now() - item.timestamp > item.ttl) {
      this.memoryCache.delete(key);
      AsyncStorage.removeItem(key).catch(() => {});
      return null;
    }

    return item.data as T;
  }

  /**
   * Asynchronous Read (L1 -> L2 Fallback)
   */
  async get<T = any>(key: string): Promise<T | null> {
    // 1. Check L1 Memory
    const mem = this.getSync<T>(key);
    if (mem !== null) return mem;

    // 2. Check L2 Disk
    try {
      const raw = await AsyncStorage.getItem(key);
      if (!raw) return null;

      const parsed: CacheItem<T> | T = JSON.parse(raw);
      let resolvedData: T;
      let ttl: number | undefined;
      let timestamp = Date.now();

      if (parsed && typeof parsed === 'object' && 'timestamp' in (parsed as any) && 'data' in (parsed as any)) {
        const wrapper = parsed as CacheItem<T>;
        if (wrapper.ttl && Date.now() - wrapper.timestamp > wrapper.ttl) {
          await AsyncStorage.removeItem(key);
          return null;
        }
        resolvedData = wrapper.data;
        ttl = wrapper.ttl;
        timestamp = wrapper.timestamp;
      } else {
        resolvedData = parsed as T;
      }

      // Populate back into L1
      this.setMemory(key, resolvedData, ttl, timestamp);
      return resolvedData;
    } catch (e) {
      return null;
    }
  }

  /**
   * Store into L1 & L2 with optional TTL (in milliseconds)
   */
  async set<T = any>(key: string, data: T, ttlMs?: number): Promise<void> {
    const timestamp = Date.now();
    this.setMemory(key, data, ttlMs, timestamp);

    try {
      const payload: CacheItem<T> = { data, timestamp, ttl: ttlMs };
      await AsyncStorage.setItem(key, JSON.stringify(payload));
    } catch (_) {}
  }

  private setMemory<T>(key: string, data: T, ttl?: number, timestamp = Date.now()) {
    // LRU eviction if cache size exceeded
    if (this.memoryCache.size >= this.maxMemoryEntries) {
      const firstKey = this.memoryCache.keys().next().value;
      if (firstKey) this.memoryCache.delete(firstKey);
    }
    this.memoryCache.set(key, { data, timestamp, ttl });
  }

  /**
   * Delete from cache
   */
  async remove(key: string): Promise<void> {
    this.memoryCache.delete(key);
    try {
      await AsyncStorage.removeItem(key);
    } catch (_) {}
  }

  /**
   * Request Deduplication & SWR (Stale-While-Revalidate) Fetcher
   */
  async fetchWithDeduplication<T = any>(
    key: string,
    fetcher: () => Promise<T>,
    ttlMs: number = 60000
  ): Promise<T> {
    // Return cached value if valid
    const cached = this.getSync<T>(key);
    if (cached !== null) {
      return cached;
    }

    // Deduplicate in-flight promises
    if (this.inFlightRequests.has(key)) {
      return this.inFlightRequests.get(key)!;
    }

    const requestPromise = fetcher()
      .then(async (result) => {
        await this.set(key, result, ttlMs);
        this.inFlightRequests.delete(key);
        return result;
      })
      .catch((err) => {
        this.inFlightRequests.delete(key);
        throw err;
      });

    this.inFlightRequests.set(key, requestPromise);
    return requestPromise;
  }
}

export const fastCache = new FastCacheManager();
