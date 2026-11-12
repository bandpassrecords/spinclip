import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import sidebar from './src/data/guide-sidebar.json' with { type: 'json' };

export default defineConfig({
  site: 'https://spinclip.bandpassrecords.com',
  redirects: { '/guide': '/guide/overview/' },
  integrations: [
    // The user guide, at /guide/.
    starlight({
      title: 'Spinclip',
      // The site's own 404 (src/pages/404.astro) serves every path.
      disable404Route: true,
      logo: { src: './src/assets/app_icon.png' },
      favicon: '/app_icon.png',
      social: [
        { icon: 'github', label: 'GitHub', href: 'https://github.com/bandpassrecords/spinclip' },
      ],
      sidebar,
      customCss: ['./src/styles/starlight.css'],
      head: [
        { tag: 'link', attrs: { rel: 'preconnect', href: 'https://fonts.googleapis.com' } },
        { tag: 'link', attrs: { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: true } },
        {
          tag: 'link',
          attrs: {
            rel: 'stylesheet',
            href: 'https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Space+Grotesk:wght@500;600;700&display=swap',
          },
        },
      ],
    }),
  ],
});
