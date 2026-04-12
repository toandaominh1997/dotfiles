#!/usr/bin/env bash

# Required brew formula packages (must be installed)
# NOTE: The rust 'dotup' CLI dynamically parses these arrays. Do not alter the syntax of the array declaration.
required_packages=(
  bash
  fzf
  git
  neovim
  tmux
  vim
  zsh
)

# Additional brew formula packages (optional)
formulae_packages=(
  ansible
  awscli
  bat
  bazelisk
  cmake
  curl
  duf
  docker
  docker-compose
  fish
  gcc
  gh
  go
  helm
  htop
  httpie
  k9s
  kubernetes-cli
  lazydocker
  lazygit
  node
  nvm
  rust
  tldr
  telnet
  terraform
  thefuck
  unzip
  wget
  zoxide
)

# Brew cask packages (macOS only)
cask_packages=(
  alt-tab
  brave-browser
  discord
  docker
  git-credential-manager
  google-chrome
  google-cloud-sdk
  iterm2
  jetbrains-toolbox
  messenger
  microsoft-edge
  microsoft-teams
  monitorcontrol
  notion
  obsidian
  postman
  rar
  slack
  spotify
  stats
  sublime-text
  telegram
  tor-browser
  visual-studio-code
  whatsapp
  zoom
)
