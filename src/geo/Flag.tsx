// URL map for every flag-icons SVG. Each file is emitted as its own asset and only
// downloaded when shown (vite.config.ts disables inlining so they stay out of the JS).
const FLAG_URLS = import.meta.glob<string>('/node_modules/flag-icons/flags/4x3/*.svg', {
  query: '?url',
  import: 'default',
  eager: true,
});

export function flagUrl(code: string): string {
  return FLAG_URLS[`/node_modules/flag-icons/flags/4x3/${code}.svg`] ?? '';
}

/** Starts downloading a flag so it appears instantly on the next question. */
export function preloadFlag(code: string): void {
  new Image().src = flagUrl(code);
}

export function Flag({ code, className = '' }: { code: string; className?: string }) {
  return <img className={`flag ${className}`} src={flagUrl(code)} alt="Flag" draggable={false} />;
}
