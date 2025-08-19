import { defineConfig } from 'vite';
import RubyPlugin from 'vite-plugin-ruby';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [
    RubyPlugin(),
    react(),
  ],
  resolve: {
    alias: {
      '@': './app/javascript',
      '@/components': './app/javascript/components',
      '@/lib': './app/javascript/lib',
    },
  },
})
