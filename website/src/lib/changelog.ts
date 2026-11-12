// The app's CHANGELOG.md, read at build time for the "What's new" page and
// the homepage's latest-version badge: one file, kept by the release process
// (RELEASING.md), never a second copy for the site.
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

export interface Section {
  title: string;
  /** Each bullet, as HTML: **bold**, `code` and [links](…) rendered. */
  items: string[];
}

export interface Release {
  version: string;
  date: string;
  sections: Section[];
}

const escape = (s: string) =>
  s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

function inline(markdown: string): string {
  return escape(markdown)
    .replace(/`([^`]+)`/g, '<code>$1</code>')
    .replace(/\*\*([^*]+)\*\*/g, '<b>$1</b>')
    .replace(/\[([^\]]+)\]\(([^)\s]+)\)/g, '<a href="$2">$1</a>');
}

let cached: Release[] | undefined;

export function changelog(): Release[] {
  if (cached) return cached;
  // `astro build` runs in website/; the changelog sits at the repo's root.
  const text = readFileSync(join(process.cwd(), '..', 'CHANGELOG.md'), 'utf8').replace(/\r\n/g, '\n');
  const releases: Release[] = [];
  let release: Release | undefined;
  let section: Section | undefined;

  for (const line of text.split('\n')) {
    const head = line.match(/^## v(\S+)\s+[—-]\s+(\d{4}-\d{2}-\d{2})/);
    if (head) {
      release = { version: head[1], date: head[2], sections: [] };
      releases.push(release);
      section = undefined;
      continue;
    }
    if (!release) continue;
    const sub = line.match(/^### (.+)/);
    if (sub) {
      section = { title: sub[1].trim(), items: [] };
      release.sections.push(section);
      continue;
    }
    if (/^- /.test(line)) {
      if (!section) {
        section = { title: 'Changes', items: [] };
        release.sections.push(section);
      }
      section.items.push(line.slice(2));
    } else if (/^\s+\S/.test(line) && section?.items.length) {
      // A bullet's continuation line.
      section.items[section.items.length - 1] += ` ${line.trim()}`;
    }
  }
  for (const r of releases) {
    r.sections = r.sections.filter((s) => s.items.length);
    for (const s of r.sections) s.items = s.items.map(inline);
  }
  return (cached = releases);
}
