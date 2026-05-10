#!/usr/bin/env bash
# Emit the system clipboard contents to stdout.
# Used by `prefix + p` to paste from the OS clipboard.
set -e
if command -v pbpaste >/dev/null 2>&1; then exec pbpaste; fi
if command -v wl-paste >/dev/null 2>&1; then exec wl-paste --no-newline; fi
if command -v xclip   >/dev/null 2>&1; then exec xclip -o -selection clipboard; fi
if command -v xsel    >/dev/null 2>&1; then exec xsel  -o -b; fi
if [ -c /dev/clipboard ]; then exec cat /dev/clipboard; fi
printf ''
