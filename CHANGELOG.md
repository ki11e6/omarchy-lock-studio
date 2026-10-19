# Changelog

## 0.1.0 (2026-10-19)

First release of Lock Studio.

### Added

- A lock screen service cloned from Omarchy's own (`omarchy.clonedFrom`), so
  the session lock, PAM password and fingerprint flows, blanking and
  stranded-lock recovery are the stock ones. A design that fails to load
  falls back to the Omarchy default design, then to a plain password field.
- 66 designs: 21 originals that follow the active Omarchy theme and need
  nothing downloaded, 38 ports of qylock themes, and 7 video wallpaper
  designs built on wallsflow.com live wallpapers.
- A picker overlay with filters, search, a font dropdown, a 24 or 12 hour
  switch, full-screen previews and keyboard navigation, opened with
  `omarchy-shell lock explore` or the opt-in Style > Lock Studio menu row.
- Personal settings: `displayName`, `avatar` (falling back to
  AccountsService, `~/.face` and `~/.face.icon`), `wallpaper` (overriding
  the Omarchy background), `wallpaperBlur` and `wallpaperDim`, validated in
  one place and settable over IPC with `omarchy-shell lock setSetting`.
- Blank modes: `off` (display off, as stock), `dim` (darken the lock surface
  and keep the panel on) and `never`, with a configurable `blankDelay`.
- Verified on-demand downloads: every asset in
  `designs/thirdparty-assets.json` is pinned to an immutable source with a
  SHA-256 digest and size, plus tools to re-pin, verify and mirror, and a
  GitHub Actions workflow that checks the catalog.
- Assets are served from this repository's `assets-1` release, with the
  pinned qylock commit as fallback.
- Full third-party notices in `NOTICE.md`: every project Lock Studio's code
  comes from, the qylock assets, the fonts and the wallpapers.
- One-time adoption of an existing Lock Designs setup: its design, clock
  format and font, and the assets it already downloaded.
- `dev.sh` to deploy a checkout locally and restart the shell.
