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
# required package 
required_packages=(
"bash"
"fzf"
"neovim"
"tmux"
"vim"
"zsh"
)

# brew formulae
formulae_packages=(
"ansible"
"awscli"
"bash"
"bat"
"bazelisk"
"cmake"
"curl"
"fish"
"fzf"
"gcc"
"gh"
"git"
"go"
"helm"
"htop"
"httpie"
"k9s"
"kubernetes-cli"
"lazydocker"
"lazygit"
"neovim"
"node"
"nvm"
"rust"
"rust"
"telnet"
"terraform"
"thefuck"
"tmux"
"unzip"
"vim"
"wget"
"zsh"
)

# brew cask
cask_packages=(
"adobe-creative-cloud"
"alacritty"
"alt-tab"
"brave-browser"
"discord"
"docker"
"git-credential-manager"
"google-chrome"
"google-cloud-sdk"
"iterm2"
"jetbrains-toolbox"
"messenger"
"microsoft-edge"
"microsoft-teams"
"miniconda"
"monitorcontrol"
"notion"
"obsidian"
"postman"
"rar"
"skype"
"slack"
"spotify"
"stats"
"sublime-text"
"telegram"
"tor-browser"
"visual-studio-code"
"visualvm"
"warp"
"whatsapp"
"zoom"
)


