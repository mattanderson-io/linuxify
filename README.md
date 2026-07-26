# linuxify

Transparently transform the macOS CLI into a fresh GNU/Linux CLI experience by

- installing missing GNU programs
- updating outdated GNU programs
- replacing pre-installed BSD programs with their preferred GNU implementation
- installing other programs common among popular GNU/Linux distributions
- coloring `ls`, `grep`/`egrep`/`fgrep`, `diff`, and the `zgrep`/`bzgrep`/`xzgrep`/`zstdgrep`
  compressed-file variants
- auto-decompressing `less` (gz/bz2/xz/zip/tar/etc.) via `lesspipe`
- an Ubuntu-style colored `user@host:~/path$` prompt and colored man pages
- a `fastfetch` system-info banner and `htop`/`tree`/`watch` for good measure
- `zsh-autosuggestions` and `zsh-syntax-highlighting`

Tested through macOS Big Sur (11), Monterey (12), Ventura (13), Sonoma (14), Sequoia (15), and Tahoe (26).

![Colored GNU CLI on macOS](screenshots/colors.png)

## Install

```bash
git clone https://github.com/mattanderson-io/linuxify.git
cd linuxify/
./linuxify install
```

## Usage

At the end of the install, files at `~/.linuxify` and `~/.zshrc` will be provided.

- `~/.linuxify` updates your PATH, MANPATH, and other variables so you get the
  GNU utilities first without needing to prepend them with `g`, and enables
  `--color=auto` plus `lesspipe` for compressed files.
- `~/.zshrc` sets up the colored prompt, colored man pages, the fastfetch
  banner, and the zsh plugins.

Source both (or open a new shell) to pick up the changes.

## Uninstall

```bash
./linuxify uninstall
```
