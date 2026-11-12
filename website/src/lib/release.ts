// The download links, read from the newest GitHub release when the site is
// built. The release workflow rebuilds the site after publishing a release, so
// the buttons always point at the files of the latest one.

const repo = 'bandpassrecords/spinclip';
export const repoUrl = `https://github.com/${repo}`;
export const releasesUrl = `${repoUrl}/releases`;
export const issuesUrl = `${repoUrl}/issues`;

export interface Downloads {
  /** e.g. "v0.3.0"; null when GitHub couldn't be reached. */
  tag: string | null;
  windowsInstaller: string;
  windowsZip: string;
  windowsMsix: string;
  macos: string;
  linux: string;
}

interface Asset {
  name: string;
  browser_download_url: string;
}

const patterns = {
  windowsInstaller: /^Spinclip_Installer_.*\.exe$/,
  windowsZip: /^Spinclip_Windows_.*\.zip$/,
  windowsMsix: /^Spinclip_Windows_.*\.msix$/,
  macos: /^Spinclip_macOS_.*\.zip$/,
  linux: /^Spinclip_Linux_.*\.tar\.gz$/,
};

let cached: Promise<Downloads> | undefined;

/** Read once per build: several pages ask. */
export function latestDownloads(): Promise<Downloads> {
  return (cached ??= fetchLatest());
}

async function fetchLatest(): Promise<Downloads> {
  // Nothing found still builds a working page: every button opens the
  // latest release, where the files are.
  const fallback = `${releasesUrl}/latest`;
  try {
    const headers: Record<string, string> = { Accept: 'application/vnd.github+json' };
    if (process.env.GITHUB_TOKEN) headers.Authorization = `Bearer ${process.env.GITHUB_TOKEN}`;
    const response = await fetch(`https://api.github.com/repos/${repo}/releases/latest`, { headers });
    if (!response.ok) throw new Error(`GitHub answered ${response.status}`);
    const release = (await response.json()) as { tag_name: string; assets: Asset[] };
    const find = (pattern: RegExp) =>
      release.assets.find((a) => pattern.test(a.name))?.browser_download_url ?? fallback;
    return {
      tag: release.tag_name,
      windowsInstaller: find(patterns.windowsInstaller),
      windowsZip: find(patterns.windowsZip),
      windowsMsix: find(patterns.windowsMsix),
      macos: find(patterns.macos),
      linux: find(patterns.linux),
    };
  } catch (error) {
    console.warn(`[release] latest release not read, linking to ${fallback}: ${error}`);
    return {
      tag: null,
      windowsInstaller: fallback,
      windowsZip: fallback,
      windowsMsix: fallback,
      macos: fallback,
      linux: fallback,
    };
  }
}
