import { useCallback, useEffect, useMemo, useRef } from 'react';

/** setTimeout that is cancelled automatically on unmount (and on demand via `clear`). */
export function useTimers() {
  const ids = useRef<number[]>([]);

  const clear = useCallback(() => {
    ids.current.forEach((id) => window.clearTimeout(id));
    ids.current = [];
  }, []);

  const later = useCallback((fn: () => void, ms: number) => {
    ids.current.push(window.setTimeout(fn, ms));
  }, []);

  useEffect(() => clear, [clear]);

  return useMemo(() => ({ later, clear }), [later, clear]);
}
