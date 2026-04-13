#!/usr/bin/env bash

install_fonts() {
  log_info "==> Installing Nerd Fonts (MesloLGS NF)..."

  local os_type
  os_type="$(detect_os)"
  local font_dir

  if [[ "$os_type" == "macos" ]]; then
    font_dir="$HOME/Library/Fonts"
  else
    font_dir="$HOME/.local/share/fonts"
  fi

  if [[ ! -d "$font_dir" ]]; then
    mkdir -p "$font_dir"
  fi

  local font_urls=(
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf"
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf"
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf"
    "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/DroidSansMono/DroidSansMNerdFont-Regular.otf"
    "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Iosevka/IosevkaNerdFontMono-Regular.ttf"
  )

  local pids=()
  local downloaded=0

  for url in "${font_urls[@]}"; do
    local font_file="${url##*/}"
    local decoded_font="${font_file//%20/ }"
    local font_path="$font_dir/$decoded_font"

    if [[ -f "$font_path" ]]; then
      log_info "Font already exists: $decoded_font"
      continue
    fi

    log_info "Downloading $decoded_font..."
    curl -fsSL "$url" -o "$font_path" &
    pids+=($!)
    downloaded=$((downloaded + 1))
  done

  if [[ ${#pids[@]} -gt 0 ]]; then
    wait "${pids[@]}" || log_warn "A font download failed"
    log_success "Fonts downloaded successfully."
  fi

  if [[ "$downloaded" -gt 0 && "$os_type" == "linux" ]] && command_exists fc-cache; then
    log_info "Updating font cache..."
    fc-cache -f -v >/dev/null 2>&1
  fi
}
