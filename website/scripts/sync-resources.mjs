// Copies the pictures and clips the site shows from the app's own resources/
// into public/resources/, so the screenshots and example renders that
// scripts/capture_screenshots.ps1 writes are the ones the site serves — never
// a second copy kept by hand. Runs before `dev` and `build`; public/resources
// is ignored.
import { cpSync, rmSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const site = join(dirname(fileURLToPath(import.meta.url)), '..');
const repo = join(site, '..');
const out = join(site, 'public', 'resources');

// Only what the pages use: resources/ also holds ffmpeg, which has no
// business on a website.
const folders = ['screenshots', 'examples'];
const media = /\.(png|jpe?g|webp|mp4)$/i;

rmSync(out, { recursive: true, force: true });
for (const folder of folders) {
  const from = join(repo, 'resources', folder);
  if (!existsSync(from)) throw new Error(`Missing ${from} — run scripts/capture_screenshots.ps1`);
  cpSync(from, join(out, folder), {
    recursive: true,
    filter: (path) => !/\.[^\/]+$/.test(path) || media.test(path),
  });
}
console.log(`resources → ${out}`);
