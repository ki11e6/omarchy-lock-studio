# Marketplace submission

Pre-filled answers for the submission issue at
https://github.com/omacom/omarchy-plugin-marketplace/issues/new?template=submit-plugin.yml

Do not file this until the plugin has been installed and tested on a real
Omarchy machine: the checklist below asserts things that need to be true,
not aspirational.

**Repository URL**
```
https://github.com/ki11e6/omarchy-lock-studio
```

**Category**
```
Appearance
```

**Tags** (max 3)
```
Quickshell, Media, System
```

**Suggest a missing tag**
```
Lock Screen
```

**Maintainer notes**
```
Lock Studio is a lock screen for Omarchy with 66 designs and a picker:
twenty-one originals that follow the active Omarchy theme and need nothing
downloaded, 38 QML ports of themes from Darkkal44/qylock (GPL-3.0), and 7
designs built on wallsflow.com live wallpapers. Personal settings cover the
displayed name, avatar, a lock wallpaper with blur and dimming, and the
blank mode (display off, dim, or never) with its delay. Every video, image
and font downloads on demand; the repository holds only QML, thumbnails and
the catalog.

The plugin is a standalone lock screen. It is a clone of omarchy.lock
(manifest `omarchy.clonedFrom`), so the session lock, PAM password and
fingerprint flows, blanking and stranded-lock recovery are Omarchy's own
code; only the drawn design changes. `service` kind for the lock, `overlay`
kind for the picker, opened with `omarchy-shell lock explore`.

Writes only to ~/.config/omarchy/lock-studio/ (designs, previews, the asset
catalog, downloaded assets, settings.json). Nothing in the plugin runs as
root or asks for a password, and no file it ships is meant to be run with
elevated rights. One opt-in script exists for the user to run:
tools/install-menu-entries.sh adds an Omarchy menu row, user files only,
and `--remove` undoes it.

Network access: on-demand downloads only, when the user clicks Download.
Every entry in designs/thirdparty-assets.json carries a repository-owned
SHA-256 and byte size and points at the assets-1 GitHub release of this
repository, with a full commit of Darkkal44/qylock
(f6561e2ceae33f26e5e660742a5df2f725cbe514) kept as a fallback mirror for the
qylock files. Three fonts that are not freely redistributable (Google Sans,
NDot55, NType82) are fetched from that qylock commit directly.
The downloader (Service.qml, fetchScript) fetches to a .part file, verifies
the digest, and only then moves the file into place; entries without a
digest are refused and mismatches are discarded and reported on the card.
Optional mirrors are tried after the primary URL and must match the same
digest. tools/pin-assets.sh regenerates the catalog, tools/verify-assets.sh
checks an installation, and .github/workflows/catalog.yml checks the catalog
on every change and can download and verify every file.

A failed design never strands a locked screen: it falls back to the shipped
Omarchy default design, then to a plain password field.

MIT licensed. The ported designs are written against this plugin's own
DesignBase and PasswordField, and qylock's assets are redistributed
unmodified under GPL-3.0 from this repository's release; see NOTICE.md.
Credits and third-party notices are in README.md and NOTICE.md; version
history is in CHANGELOG.md.
```

**Submission checklist**
- [x] The repository is public and contains installation and removal instructions.
- [x] I have documented the plugin license and any external dependencies.
- [x] I confirm that I own or have permission to submit this plugin and its preview assets.
- [x] The plugin does not overwrite user configuration without explicit consent.
- [x] I understand that approval is for listing and is not a security review.
