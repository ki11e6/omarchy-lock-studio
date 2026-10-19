# Third-party notices

Lock Studio is MIT licensed (see `LICENSE`). It builds on the projects
below; their notices are reproduced here as their licenses require.

## MIT-licensed code

Lock Studio contains code derived from these projects:

- **[Lock Designs](https://github.com/SmoothPixels/lock-designs)**,
  Copyright (c) 2026 Jean Alvarado. The base Lock Studio grew from: the
  design host, the picker, the verified downloader and the designs.
- **[Omarchy](https://github.com/omacom/omarchy)**, Copyright (c) David
  Heinemeier Hansson. `Service.qml` is a clone of Omarchy's `omarchy.lock`
  plugin (made with the `clonedFrom` manifest field), so the session lock,
  PAM and display-blanking flow are the stock ones. The weather widget
  imports Omarchy's weather `Model.js`, and the network and power widgets
  follow Omarchy's own panel and menu.
- **[zen-lock](https://github.com/rover-001/zen-lock)**, Copyright (c) 2026
  Parth Sharma (rover-001). The lock wallpaper override, the avatar fallback
  chain and the dim blank mode.
- **[omaarch.lock](https://github.com/archlatam/omaarch.lock)**, Copyright
  (c) 2026 archlatam. The media and volume widget approach.
- **[omalock](https://github.com/asdfsnlr/omalock)**, Copyright (c) 2026
  asdfsnlr (its LICENSE names no holder, so it is credited to the project's
  owner). The image fetch ported into `widgets/fetch-image.sh`, the weather
  and network widgets, the corner layout, the avatar shape and the date and
  time formats.

Each of them is used under the MIT License:

```
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```

## qylock (GPL-3.0)

The 38 ported designs are inspired by themes from
[Darkkal44/qylock](https://github.com/Darkkal44/qylock), licensed under the
GNU General Public License v3.0. Their QML is written against this plugin's
own components and is not copied from qylock's source.

Their video, image and font files are redistributed unmodified from the
`assets-1` release of this repository, with qylock's own copies at commit
`f6561e2ceae33f26e5e660742a5df2f725cbe514` as the fallback; every file is
verified against the SHA-256 digest in `designs/thirdparty-assets.json`. The
GPL-3.0 text ships in that release as `qylock-LICENSE.txt`, and the source
is at
https://github.com/Darkkal44/qylock/tree/f6561e2ceae33f26e5e660742a5df2f725cbe514.
None of these files are in git.

## Fonts

The fonts come with the qylock themes. Each redistributed font's license
file is in the `assets-1` release.

| Font | Designs | License | Copyright | License file |
|---|---|---|---|---|
| Outfit | Clockwork (Orbital / Neo Orbital / Tape), The Last of Us | SIL OFL 1.1 | Copyright 2021 The Outfit Project Authors | `OFL-outfit.txt` |
| Orbitron | Dog Samurai, Enfield, Field, Winter, Wuthering Waves | SIL OFL 1.1 | Copyright 2018 The Orbitron Project Authors, with Reserved Font Name "Orbitron" | `OFL-orbitron.txt` |
| Figtree | Forest | SIL OFL 1.1 | Copyright 2022 The Figtree Project Authors | `OFL-figtree.txt` |
| Itim | Girl Coffee, Girl Pillow, Man Bicycle, Women Umbrella | SIL OFL 1.1 | Copyright (c) 2015, Cadson Demak; Copyright (c) 2014, Pablo Impallari | `OFL-itim.txt` |
| Pixelify Sans | the eleven Pixel designs | SIL OFL 1.1 | Copyright 2021 The Pixelify Sans Project Authors | `OFL-pixelifysans.txt` |
| Cinzel | Reverse: 1999 (I / II) | SIL OFL 1.1 | Copyright 2020 The Cinzel Project Authors | `OFL-cinzel.txt` |
| Tektur | Ninja Gaiden | SIL OFL 1.1 | Copyright 2023 The Tektur Project Authors | `OFL-tektur.txt` |
| DejaVu Sans | Nine Sols | Bitstream Vera license; DejaVu changes are public domain | Copyright (c) 2003 by Bitstream, Inc. | `DejaVu-LICENSE.txt` |
| The Last Shuriken | Sword | No license stated; re-hosted at the maintainer's choice | Copyright 2021 Arterfak Project. All rights reserved. | none |
| Google Sans | Material You (Dark) | Not freely redistributable | not stated here | not re-hosted, fetched from qylock |
| NDot55, NType82 | Nothing | Not freely redistributable | not stated here | not re-hosted, fetched from qylock |

## Wallpapers

The videos and images belong to their artists and to the sites credited per
design in `README.md`: Wallsflow, MoeWalls, YouTube, Pixiv, Reddit, Taptap,
Noisy Pixel, Terraria Forums and the Minecraft Wiki. The seven car and cat
designs marked `// source: wallsflow` use live wallpapers from
[wallsflow.com](https://wallsflow.com); that site blocks scripted downloads,
so those videos are served from the `assets-1` release of this repository
with their SHA-256 digests in the same catalog.
