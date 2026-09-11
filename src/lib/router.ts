import { useEffect, useState } from 'react';

// Hash routing (#/chess, #/geo/flags/europe) works on any static host with no rewrite rules.
function currentPath(): string {
  return window.location.hash.replace(/^#/, '') || '/';
}

export function useHashPath(): string {
  const [path, setPath] = useState(currentPath);
  useEffect(() => {
    const onChange = () => setPath(currentPath());
    window.addEventListener('hashchange', onChange);
    return () => window.removeEventListener('hashchange', onChange);
  }, []);
  return path;
}
