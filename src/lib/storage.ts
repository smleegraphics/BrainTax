// localStorage wrappers that never throw: private browsing or blocked storage just means
// progress isn't remembered, not a broken page.

export function load<T extends object>(key: string, fallback: T): T {
  try {
    const raw = localStorage.getItem(key);
    // Merge over the defaults so fields added in later versions get sensible values.
    return raw ? { ...fallback, ...JSON.parse(raw) } : fallback;
  } catch {
    return fallback;
  }
}

export function save(key: string, value: unknown): void {
  try {
    localStorage.setItem(key, JSON.stringify(value));
  } catch {
    // Storage unavailable; keep playing without persistence.
  }
}

export function remove(key: string): void {
  try {
    localStorage.removeItem(key);
  } catch {
    // Nothing to clear.
  }
}
