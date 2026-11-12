---
title: Installation
description: Installing Spinclip on Windows, macOS and Linux, and getting past the first-run warnings.
---

Download Spinclip from the [homepage](/#download) or from the [releases on GitHub](https://github.com/bandpassrecords/spinclip/releases/latest). Each file there has a `.sha256` checksum next to it.

## Windows

Windows 10 or later, 64-bit. Three downloads, the same app:

| File | What it is |
|---|---|
| `Spinclip_Installer_vX.Y.Z.exe` | An installer, with a Start menu entry and an uninstaller. The one to pick if unsure. |
| `Spinclip_Windows_vX.Y.Z.zip` | Portable: unzip anywhere and run `spinclip.exe`. |
| `Spinclip_Windows_vX.Y.Z.msix` | A Windows app package. |

Spinclip isn't code-signed yet, so the first time Windows may show **Windows protected your PC**. Choose **More info**, then **Run anyway**.

FFmpeg comes with the app — there's nothing else to install.

## macOS

macOS 10.15 or later. Unzip `Spinclip_macOS_vX.Y.Z.zip` and drag **Spinclip** to your Applications folder.

Spinclip isn't notarized by Apple yet, so the first launch is blocked. Open **System Settings → Privacy & Security**, scroll down, and click **Open Anyway** next to the message about Spinclip.

FFmpeg comes with the app. It's built for Intel Macs: on Apple silicon, macOS may offer to install **Rosetta** the first time you render — accept, and it runs from then on.

## Linux

Unpack `Spinclip_Linux_vX.Y.Z.tar.gz` and run `spinclip` from the folder.

On Linux, Spinclip uses the FFmpeg installed on your system, so install it first:

```bash
sudo apt install ffmpeg        # Debian, Ubuntu
sudo dnf install ffmpeg        # Fedora (RPM Fusion)
sudo pacman -S ffmpeg          # Arch
```

If FFmpeg lives somewhere unusual, set `FFMPEG_PATH` to the folder that holds `ffmpeg` and `ffprobe`.
