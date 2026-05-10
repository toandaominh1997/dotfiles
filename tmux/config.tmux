# Reference: https://github.com/gpakosz/.tmux/blob/master/.tmux.conf
# Targets tmux >= 3.0 (uses %if and #{e|...} math expansion).


# -- general -------------------------------------------------------------------

set -g default-terminal "tmux-256color"
setw -g mode-keys vi                      # vi keys in copy/choice modes
set -s escape-time 0                      # faster command sequences (0ms for neovim)
set -sg repeat-time 600                   # increase repeat timeout
set -s focus-events on

set -g prefix2 C-a                        # GNU-Screen compatible prefix
bind C-a send-prefix -2

set-option -g mouse on
set -g history-limit 50000                # boost history

# edit configuration
bind e new-window -n "#{TMUX_CONF_LOCAL}" sh -c '${EDITOR:-vim} "$TMUX_CONF_LOCAL" && "$TMUX_PROGRAM" ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} source "$TMUX_CONF" \; display "$TMUX_CONF_LOCAL sourced"'

# reload configuration
bind r source-file ~/.dotfiles/tool/tmux/config.tmux \; display "Reloaded!"

# -- display -------------------------------------------------------------------

set -g base-index 1           # start windows numbering at 1
setw -g pane-base-index 1     # make pane numbering consistent with windows

setw -g automatic-rename on   # rename window to reflect current program
set -g renumber-windows on    # renumber windows when a window is closed

set -g set-titles on          # set terminal title

set -g display-panes-time 800 # slightly longer pane indicators display time
set -g display-time 1000      # slightly longer status messages display time

# activity
set -g monitor-activity on
set -g visual-activity off

# -- navigation ----------------------------------------------------------------

# create / find session
bind C-c new-session
bind C-f command-prompt -p find-session 'switch-client -t %%'
bind BTab switch-client -l                # move to last session

# split current window
bind - split-window -v
bind _ split-window -h

# pane navigation (prefix-based)
bind -r h select-pane -L
bind -r j select-pane -D
bind -r k select-pane -U
bind -r l select-pane -R
bind > swap-pane -D
bind < swap-pane -U

# maximize current pane
bind + run "cut -c3- '#{TMUX_CONF}' | sh -s _maximize_pane '#{session_name}' '#D'"

# pane resizing
bind -r H resize-pane -L 2
bind -r J resize-pane -D 2
bind -r K resize-pane -U 2
bind -r L resize-pane -R 2

# window navigation
unbind n
unbind p
bind -r C-h previous-window
bind -r C-l next-window
bind Tab last-window

# toggle mouse
bind m if -F "#{mouse}" \
    "set-option -g mouse off; display 'Mouse: OFF'" \
    "set-option -g mouse on;  display 'Mouse: ON'"

# toggle synchronize-panes (broadcast keystrokes to every pane in window)
bind a if -F "#{pane_synchronized}" \
    "setw synchronize-panes off; display 'Sync: OFF'" \
    "setw synchronize-panes on;  display 'Sync: ON'"

# popup keybindings cheatsheet (tmux >= 3.2)
%if #{e|>=:#{version},3.2}
bind ? display-popup -E -w 80% -h 80% 'tmux list-keys | less -R'
%endif

# -- copy mode -----------------------------------------------------------------
#
# Native-feeling copy/paste:
#   drag             → tmux-yank copies selection to system clipboard (mouse end → cancel)
#   double-click     → select word + copy
#   triple-click     → select line + copy
#   y (in copy mode) → copy + cancel
#   prefix + p       → paste from system clipboard
#
# All clipboard I/O goes through tmux/scripts/{clip,paste}.sh which auto-detect
# pbcopy / wl-copy / xclip / xsel / clip.exe. tmux-yank uses the same helper via
# @override_copy_command (see plugins section). OSC 52 also fires when
# set-clipboard is on, so SSH + nested terminals work too.

bind Enter copy-mode

bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi C-v send -X rectangle-toggle
bind -T copy-mode-vi y send -X copy-pipe-and-cancel '~/.dotfiles/tool/tmux/scripts/clip.sh'
bind -T copy-mode-vi Escape send -X cancel
bind -T copy-mode-vi H send -X start-of-line
bind -T copy-mode-vi L send -X end-of-line

# Word/line selection by double/triple-click (tmux-yank only handles drag).
bind -T copy-mode-vi DoubleClick1Pane send -X select-word \; send -X copy-pipe-and-cancel '~/.dotfiles/tool/tmux/scripts/clip.sh'
bind -T copy-mode-vi TripleClick1Pane send -X select-line \; send -X copy-pipe-and-cancel '~/.dotfiles/tool/tmux/scripts/clip.sh'
bind -n DoubleClick1Pane select-pane \; copy-mode -M \; send -X select-word \; send -X copy-pipe-and-cancel '~/.dotfiles/tool/tmux/scripts/clip.sh'
bind -n TripleClick1Pane select-pane \; copy-mode -M \; send -X select-line \; send -X copy-pipe-and-cancel '~/.dotfiles/tool/tmux/scripts/clip.sh'


# -- buffers -------------------------------------------------------------------

bind b list-buffers
bind P choose-buffer
# prefix+p pastes from the system clipboard (cross-platform via paste.sh)
bind p run-shell '~/.dotfiles/tool/tmux/scripts/paste.sh | "$TMUX_PROGRAM" ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} load-buffer - \; paste-buffer'


# -- session pickers (tms is defined in zshrc) --------------------------------
# Use display-popup on tmux >= 3.2, fall back to split-window otherwise.
%if #{e|>=:#{version},3.2}
bind C display-popup -E -w 60% -h 60% 'bash -ci "tms -ask"'
bind S display-popup -E -w 60% -h 60% 'bash -ci tms'
%else
bind C run "tmux split-window -l 1 'bash -ci \"tms -ask\"'"
bind S run "tmux split-window -l 10 'bash -ci tms'"
%endif


# -- colors / styles -----------------------------------------------------------

# Note: tmux-256color terminfo comes with ncurses (/usr/share/terminfo/t/tmux-256color).
# It enables true color, undercurl, clipboard (OSC 52), and mouse events in iTerm2.
# If missing, reinstall ncurses.

# Clear accumulated overrides from previous source-file reloads, then set once.
set-option -s terminal-overrides ""
set-option -s -a terminal-overrides ",*:Tc"
set-option -s -a terminal-overrides ',*:Smulx=\E[4::%p1%dm'
set-option -s -a terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'
set-option -s -a terminal-overrides ',*:Ms=\E]52;c;%p2%s\007'
set-option -s -a terminal-overrides ',*:XT'

# Enable mouse / clipboard / focus features for xterm-compatible terminals
set-option -s terminal-features ""
set-option -s -a terminal-features "xterm*:clipboard:ccolour:cstyle:focus:title:mouse:extkeys"
set-option -s -a terminal-features "screen*:title"
set-option -s -a terminal-features "rxvt*:ignorefkeys"

# Pane borders — visible accent on active, subtle gray on inactive
set-option -g pane-border-style 'fg=#3b4048'
set-option -g pane-active-border-style 'fg=#61afef'

# Command + copy mode messages
set-option -g message-style 'fg=#abb2bf,bg=#282c34'
set-option -w -g mode-style 'fg=#abb2bf,bg=#3b4048'

# Disable jarring highlight on activity windows
set-option -g window-status-activity-style 'bold'

# Status line
source ~/.dotfiles/tool/tmux/statusline.tmux


# -- plugins -------------------------------------------------------------------

# Auto install tmux plugin manager if it is not installed
if "test ! -d ~/.tmux/plugins/tpm" \
   "run 'git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm'"

set-option -g @tpm_plugins ' \
    tmux-plugins/tpm \
    tmux-plugins/tmux-yank \
    tmux-plugins/tmux-battery \
    tmux-plugins/tmux-resurrect \
    tmux-plugins/tmux-continuum \
    tmux-plugins/tmux-online-status \
    christoomey/vim-tmux-navigator \
    laktak/extrakto \
    wfxr/tmux-fzf-url \
'

set-environment -g TMUX_PLUGIN_MANAGER_PATH '$HOME/.tmux/plugins/'
# First-run bootstrap: probe a plugin we always keep
if "test ! -d ~/.tmux/plugins/tmux-yank" \
   "run '~/.tmux/plugins/tpm/bin/install_plugins'"

# Battery icons (require Nerd Font)
set-option -g @batt_icon_charge_tier1 ''
set-option -g @batt_icon_charge_tier2 ''
set-option -g @batt_icon_charge_tier3 ''
set-option -g @batt_icon_charge_tier4 ''
set-option -g @batt_icon_charge_tier5 ''
set-option -g @batt_icon_charge_tier6 ''
set-option -g @batt_icon_charge_tier7 ''
set-option -g @batt_icon_charge_tier8 ''
set-option -g @batt_icon_status_charged ''
set-option -g @batt_icon_status_charging ''

# Continuum + resurrect (use prefix+C-r to restore, prefix+C-s to save)
set-option -g @continuum-save-interval '3'
set-option -g @resurrect-capture-pane-contents 'on'
set-option -g @resurrect-processes 'ssh mosh-client pgcli mssql-cli litecli ranger fzf'

# Extrakto (hint-based extract/copy from screen — prefix + Tab)
set-option -g @extrakto_split_direction "v"
set-option -g @extrakto_key "tab"
set-option -g @extrakto_split_size "15"
set-option -g @extrakto_insert_key "enter"
set-option -g @extrakto_copy_key "ctrl-y"

# Online status indicator
set-option -g @online_icon ''
set-option -g @offline_icon ''

# tmux-yank: route system-clipboard copy through our cross-platform helper,
# so y / Y / mouse-drag end up in pbcopy/wl-copy/xclip uniformly.
set-option -g @override_copy_command '~/.dotfiles/tool/tmux/scripts/clip.sh'
set-option -g @yank_selection_mouse 'clipboard'

# Enable clipboard integration (iTerm2 / OSC 52)
set-option -g set-clipboard on

# Local config — sourced BEFORE TPM so it can override plugin defaults
if-shell "[ -f ~/.dotfiles/tool/tmux/local.tmux ]" 'source ~/.dotfiles/tool/tmux/local.tmux'
if-shell "[ -f ~/.tmux.conf.local ]" 'source ~/.tmux.conf.local'

# Initialize TMUX plugin manager (this must be the last line of the conf file)
run-shell '~/.tmux/plugins/tpm/tpm'
