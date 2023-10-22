#!/bin/bash


command_exists() {
  brew list $1 &>/dev/null
}

install_package() {
  local package=$1
  local has_upgrade=$2
  local formulae=$3
  if command_exists "$package"
  then
    echo "$package is installed"
    if [[ $has_upgrade == "upgrade" || $has_upgrade == "-U" || $has_upgrade == "--upgrade" ]];
    then
      echo upgrade $package ...
      brew upgrade $package
    fi
  else
    if [[ $formulae == "--cask" ]];
    then
      echo "install $package throught out cask"
      brew install $formulae $1
    else
      echo "$package installed before"
      brew install $1 
    fi
  fi
}

install_brew_packages() {
  local list_package=("${@:1:$#-2}")
  local has_upgrade="${@:$#-1:1}"
  local formulae="${!#}"
  for package in "${list_package[@]}"; do 
    install_package $package $has_upgrade $formulae
  done
}

# brew formulae
formulae_packages=(
"git"
"lazygit"
"lazydocker"
"gh"
"curl"
"wget"
"vim"
"neovim"
"bash"
"zsh"
"tmux"
"fish"
"bat"
"cmake"
"telnet"
"htop"
"httpie"
"thefuck"
"unzip"
"fzf"
## Programing language
"gcc"
"go"
"rust"
"node"
## Devops
"k9s"
"kubernetes-cli"
"helm"
"terraform"
"ansible"
"bazelisk"
)

# brew cask
cask_packages=(
"visual-studio-code"
"zoom"
"iterm2"
"docker"
"google-chrome"
"postman"
"warp"
"spotify"
"zoom"
"slack"
"discord"
"sublime-text"
"obsidian"
"microsoft-edge"
"microsoft-teams"
"stats"
"brave-browser"
"telegram"
"notion"
"whatsapp"
"alacritty"
"jetbrains-toolbox"
"skype"
"adobe-creative-cloud"
"visualvm"
)


