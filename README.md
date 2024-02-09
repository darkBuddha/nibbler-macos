# Nibbler macOS install script

This script installs the lastest [Nibbler](https://github.com/rooklift/nibbler) on your macOS system with a single command:

```bash
curl -s https://raw.githubusercontent.com/darkBuddha/nibbler-macos/main/install_nibbler_macos.sh | bash
```

## Requirements

Everything is installed automatically, if needed.

* [Git](https://git-scm.com/)
* [Node.js](https://nodejs.org/)
* [NPM](https://www.npmjs.com/)
* [librsvg](https://wiki.gnome.org/Projects/LibRsvg)

## Features

* builds and installs the latest Nibbler directly from the [official repository](https://github.com/rooklift/nibbler)
* automatically detects/installs [Leela Chess Zero](https://lczero.org/) (Lc0) and [Stockfish](https://stockfishchess.org/), and configures them for use with Nibbler
* works on Apple Silicon and Intel
* adds Nibbler version to `package.json`, so the "about" windows of Nibbler shows the correct version instead of `1.0.0`
* HQ icon from Nibbler project
