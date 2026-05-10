#!/usr/bin/env bash
# Pipe stdin to whichever system clipboard tool is available.
# Used by tmux copy bindings (mouse drag, y, double/triple-click).
set -e
if command -v pbcopy >/dev/null 2>&1; then exec pbcopy; fi
if command -v wl-copy >/dev/null 2>&1; then exec wl-copy; fi
if command -v xclip  >/dev/null 2>&1; then exec xclip -i -selection clipboard; fi
if command -v xsel   >/dev/null 2>&1; then exec xsel  -i -b; fi
if command -v clip.exe >/dev/null 2>&1; then exec clip.exe; fi
if [ -c /dev/clipboard ]; then exec dd of=/dev/clipboard 2>/dev/null; fi
cat >/dev/null
