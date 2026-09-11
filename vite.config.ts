/// <reference types="vitest/config" />
import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

export default defineConfig({
  plugins: [react()],
  // Fixed ports (off Vite's 5173/4173 defaults) so BrainTax doesn't collide with other local projects.
  server: { port: 5273, strictPort: true },
  preview: { port: 4273, strictPort: true },
  build: {
    // Keep every flag SVG as a separate file fetched on demand instead of inlining
    // hundreds of them into the JS bundle.
    assetsInlineLimit: 0,
  },
  test: {
    environment: 'node',
  },
});
