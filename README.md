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

The install writes two files and sources both from your `~/.zshrc`, so a new
shell picks everything up with no further setup:

- `~/.linuxify` updates your PATH, MANPATH, and other variables so you get the
  GNU utilities first without needing to prepend them with `g`, and enables
  `--color=auto` plus `lesspipe` for compressed files. Shell-agnostic.
- `~/.linuxify.zsh` sets up the colored prompt, colored man pages, the
  fastfetch banner, and the zsh plugins. zsh only.

Your existing `~/.zshrc` is never overwritten — the two `.` lines are appended
if missing, and a copy is kept at `~/.zshrc.linuxify.bak`. If you use bash,
add `. ~/.linuxify` to your `~/.bashrc` yourself.

The screenshot above uses the Ubuntu font, which is not installed by the
script. To match it:

```bash
brew install --cask font-ubuntu font-ubuntu-mono
```

then pick Ubuntu Mono in Terminal → Settings → Profiles → Text.

## Uninstall

```bash
./linuxify uninstall
```

This removes both files and strips the lines it added to your `~/.zshrc`.
