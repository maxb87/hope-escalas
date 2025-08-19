import { defineConfig } from 'vite';
import { fileURLToPath, URL } from 'node:url';
import RubyPlugin from 'vite-plugin-ruby';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [
    RubyPlugin(),
    react(),
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./app/frontend', import.meta.url)),
      '@/components': fileURLToPath(new URL('./app/frontend/components', import.meta.url)),
      '@/lib': fileURLToPath(new URL('./app/frontend/lib', import.meta.url)),
    },  
  },
})
