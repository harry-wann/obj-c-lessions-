// @ts-check
import { defineConfig } from 'astro/config';
import mdx from '@astrojs/mdx';
import preact from '@astrojs/preact';
import tailwindcss from '@tailwindcss/vite';
import { AstroPWAIntegration as AstroPWA } from '@vite-pwa/astro';

export default defineConfig({
  site: 'https://harry-wann.github.io',
  base: '/obj-c-lessions-',
  trailingSlash: 'ignore',
  integrations: [mdx(), preact(), AstroPWA({
    base: '/obj-c-lessions-/',
    scope: '/obj-c-lessions-/',
    registerType: 'autoUpdate',
    manifest: {
      name: 'Objective-C 速成',
      short_name: 'ObjC 速成',
      lang: 'zh-Hant-TW',
      start_url: '/obj-c-lessions-/',
      display: 'standalone',
      background_color: '#f2f2f7',
      theme_color: '#007aff',
      icons: [{ src: '/obj-c-lessions-/icon.svg', sizes: 'any', type: 'image/svg+xml', purpose: 'any' }],
    },
    workbox: {
      navigateFallback: null,
      globPatterns: ['**/*.{html,js,css,svg,json,woff2}'],
      globIgnores: ['**/pagefind/**'],
      runtimeCaching: [{ urlPattern: ({ url }) => url.pathname.includes('/pagefind/'), handler: 'StaleWhileRevalidate', options: { cacheName: 'pagefind' } }],
    },
  })],
  vite: { plugins: [tailwindcss()] },
  markdown: {
    shikiConfig: {
      themes: { light: 'github-light', dark: 'github-dark' },
      defaultColor: false,
      wrap: false,
    },
  },
});
