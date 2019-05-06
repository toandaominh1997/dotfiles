set +e
set -u

if [ -d ~/.toandaominh1997/.dotfiles ] ; then
cd ~/.toandaominh1997/.dotfiles
git pull origin master
fi

if ! is_app_installed vim; then
  printf "WARNING: \"vim\" command is not found. \
Install it first\n"
  apt-get install vim
fi

echo '
set runtimepath+=~/.toandaominh1997/.dotfiles
source ~/.toandaominh1997/.dotfiles/vimrcs/plugin.vim
source ~/.toandaominh1997/.dotfiles/vimrcs/basic.vim
'> ~/.vimrc

if [ ! -d ~/.toandaominh1997/bundle ] ; then
git clone https://github.com/VundleVim/Vundle.vim.git ~/.toandaominh1997/bundle/Vundle.vim
fi

vim -E +PluginInstall +qall
if [ -d ~/.toandaominh1997/bundle/youcompleteme ] ; then
echo 'Install youcompleteme'
cd ~/.toandaominh1997/bundle/youcompleteme
python3 install.py --all
fi

echo "Installed Vim configuration successfully ^~^"


is_app_installed() {
  type "$1" &>/dev/null
}

REPODIR="$(cd "$(dirname "$0")"; pwd -P)"
cd "$REPODIR";

if ! is_app_installed tmux; then
  printf "WARNING: \"tmux\" command is not found. \
Install it first\n"
  apt-get insatll tmux
fi

if [ ! -e "$HOME/.tmux/plugins/tpm" ]; then
  printf "WARNING: Cannot found TPM (Tmux Plugin Manager) \
 at default location: \$HOME/.tmux/plugins/tpm.\n"
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

if [ -e "$HOME/.tmux.conf" ]; then
  printf "Found existing .tmux.conf in your \$HOME directory. Will create a backup at $HOME/.tmux.conf.bak\n"
fi

cp -f "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak" 2>/dev/null || true
cp -a ./tmuxs/. "$HOME"/.tmux/
ln -sf .tmux/tmux.conf "$HOME"/.tmux.conf;

# Install TPM plugins.
# TPM requires running tmux server, as soon as `tmux start-server` does not work
# create dump __noop session in detached mode, and kill it when plugins are installed
printf "Install TPM plugins\n"
tmux new -d -s __noop >/dev/null 2>&1 || true 
tmux set-environment -g TMUX_PLUGIN_MANAGER_PATH "~/.tmux/plugins"
"$HOME"/.tmux/plugins/tpm/bin/install_plugins || true
tmux kill-session -t __noop >/dev/null 2>&1 || true

printf "OK: Completed\n"



if ! hash zsh; then
apt-get install -y zsh
fi
cd 
if [ ! -d ~/.toandaominh1997/.oh-my-zsh ] ; then
echo 'Install Oh my zsh'
# sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.toandaominh1997/.oh-my-zsh
fi

cd
if [ ! -d ~/.toandaominh1997/fonts ] ; then
git clone https://github.com/powerline/fonts.git ~/.toandaominh1997/fonts
sh ~/.toandaominh1997/fonts/install.sh
fi


cd
if [ ! -d ~/.toandaominh1997/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ] ; then
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.toandaominh1997/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
fi

cd
if [ ! -d ~/.toandaominh1997/.oh-my-zsh/custom/plugins/zsh-autosuggestions ] ; then
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.toandaominh1997/.oh-my-zsh/custom/plugins/zsh-autosuggestions
fi

echo '
source ~/.toandaominh1997/.dotfiles/zshrcs/basic.zsh
'> ~/.zshrc
cd
export ZSH=~/.toandaominh1997/tools/install.sh
sh ~/.toandaominh1997/.oh-my-zsh/tools/install.sh
echo 'Complete OH MY ZSH'

printf "OK: Completed\n"



