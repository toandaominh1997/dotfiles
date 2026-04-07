# Reference: https://github.com/gpakosz/.tmux/blob/master/.tmux.conf


# -- general -------------------------------------------------------------------

set -g default-terminal "screen-256color"

setw -g xterm-keys on
set -s escape-time 10                     # faster command sequences
set -sg repeat-time 600                   # increase repeat timeout
set -s focus-events on

set -g prefix2 C-a                        # GNU-Screen compatible prefix
bind C-a send-prefix -2

set -q -g status-utf8 on                  # expect UTF-8 (tmux < 2.2)
setw -q -g utf8 on

set-option -g mouse on
set -g history-limit 5000                 # boost history

# edit configuration
bind e new-window -n "#{TMUX_CONF_LOCAL}" sh -c '${EDITOR:-vim} "$TMUX_CONF_LOCAL" && "$TMUX_PROGRAM" ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} source "$TMUX_CONF" \; display "$TMUX_CONF_LOCAL sourced"'

# reload configuration
# bind r run '"$TMUX_PROGRAM" ${TMUX_SOCKET:+-S "$TMUX_SOCKET"} source "$TMUX_CONF"' \; display "#{TMUX_CONF} sourced"
bind r source-file ~/.dotfiles/tool/tmux/config.tmux \; display "Reloaded!"

# -- display -------------------------------------------------------------------

set -g base-index 1           # start windows numbering at 1
setw -g pane-base-index 1     # make pane numbering consistent with windows

setw -g automatic-rename on   # rename window to reflect current program
set -g renumber-windows on    # renumber windows when a window is closed

set -g set-titles on          # set terminal title

set -g display-panes-time 800 # slightly longer pane indicators display time
set -g display-time 1000      # slightly longer status messages display time

set -g status-interval 10     # redraw status line every 10 seconds

# clear both screen and history
bind -n C-l send-keys C-l \; run 'sleep 0.2' \; clear-history

# activity
set -g monitor-activity on
set -g visual-activity off

# -- navigation ----------------------------------------------------------------

# create session
bind C-c new-session

# find session
bind C-f command-prompt -p find-session 'switch-client -t %%'

# session navigation
bind BTab switch-client -l  # move to last session

# split current window horizontally
bind - split-window -v
# split current window vertically
bind _ split-window -h

# pane navigation
bind -r h select-pane -L  # move left
bind -r j select-pane -D  # move down
bind -r k select-pane -U  # move up
bind -r l select-pane -R  # move right
bind > swap-pane -D       # swap current pane with the next one
bind < swap-pane -U       # swap current pane with the previous one

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
bind -r C-h previous-window # select previous window
bind -r C-l next-window     # select next window
bind Tab last-window        # move to last active window

# toggle mouse
bind m run "cut -c3- '#{TMUX_CONF}' | sh -s _toggle_mouse"

# -- copy mode -----------------------------------------------------------------

bind Enter copy-mode # enter copy mode

bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi C-v send -X rectangle-toggle
bind -T copy-mode-vi y send -X copy-selection-and-cancel
bind -T copy-mode-vi Escape send -X cancel
bind -T copy-mode-vi H send -X start-of-line
bind -T copy-mode-vi L send -X end-of-line

# copy to X11 clipboard
if -b 'command -v xsel > /dev/null 2>&1' 'bind y run -b "\"\$TMUX_PROGRAM\" \${TMUX_SOCKET:+-S \"\$TMUX_SOCKET\"} save-buffer - | xsel -i -b"'
if -b '! command -v xsel > /dev/null 2>&1 && command -v xclip > /dev/null 2>&1' 'bind y run -b "\"\$TMUX_PROGRAM\" \${TMUX_SOCKET:+-S \"\$TMUX_SOCKET\"} save-buffer - | xclip -i -selection clipboard >/dev/null 2>&1"'
# copy to Wayland clipboard
if -b 'command -v wl-copy > /dev/null 2>&1' 'bind y run -b "\"\$TMUX_PROGRAM\" \${TMUX_SOCKET:+-S \"\$TMUX_SOCKET\"} save-buffer - | wl-copy"'
# copy to macOS clipboard
if -b 'command -v pbcopy > /dev/null 2>&1' 'bind y run -b "\"\$TMUX_PROGRAM\" \${TMUX_SOCKET:+-S \"\$TMUX_SOCKET\"} save-buffer - | pbcopy"'
if -b 'command -v reattach-to-user-namespace > /dev/null 2>&1' 'bind y run -b "\"\$TMUX_PROGRAM\" \${TMUX_SOCKET:+-S \"\$TMUX_SOCKET\"} save-buffer - | reattach-to-usernamespace pbcopy"'
# copy to Windows clipboard
if -b 'command -v clip.exe > /dev/null 2>&1' 'bind y run -b "\"\$TMUX_PROGRAM\" \${TMUX_SOCKET:+-S \"\$TMUX_SOCKET\"} save-buffer - | clip.exe"'
if -b '[ -c /dev/clipboard ]' 'bind y run -b "\"\$TMUX_PROGRAM\" \${TMUX_SOCKET:+-S \"\$TMUX_SOCKET\"} save-buffer - > /dev/clipboard"'


# -- buffers -------------------------------------------------------------------

bind b list-buffers     # list paste buffers
bind p paste-buffer -p  # paste from the top paste buffer
bind P choose-buffer    # choose which buffer to paste from


# Smart pane switching with awareness of Vim splits.
# See: https://github.com/christoomey/vim-tmux-navigator
is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
    | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?)(diff)?$'"
bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'
tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
    "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
    "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

bind-key -T copy-mode-vi 'C-h' select-pane -L
bind-key -T copy-mode-vi 'C-j' select-pane -D
bind-key -T copy-mode-vi 'C-k' select-pane -U
bind-key -T copy-mode-vi 'C-l' select-pane -R
bind-key -T copy-mode-vi 'C-\' select-pane -l

# Utils
# Create sessions with fzf (tms is defined in bashrc)
bind-key C run "tmux split-window -l 1 'bash -ci \"tms -ask\"'"
# Switch/kill sessions with fzf (tms is defined in bashrc)
bind-key S run "tmux split-window -l 10 'bash -ci tms'"

# Colors 

# Note: this terminfo comes with ncurses (it is needed for colored undecurl to
# work). It should be located at: /usr/share/terminfo/t/tmux-256color
# If it isn't reinstall ncurses
set-option -g default-terminal "screen-256color"

# Define terminal overrides (note that when adding terminal overrides we use a
# generic `*` catchall because `tmux info` doesn't report `tmux-256color` even
# with the above default-terminal setting).
# Enable 24-bit color support (check if this works via `tmux info | grep Tc`)
set-option -s -a terminal-overrides ",*:Tc"
# Add Undercurl (test it with `printf '\e[4:3mUndercurl\n\e[0m'`)
set-option -s -a terminal-overrides ',*:Smulx=\E[4::%p1%dm'
# Add colored undercurl (test it with `printf '\e[4:3;58:2:255:100:0mUndercurl\n\e[0m'`)
set-option -s -a terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'

# Pane border (use same color for active and foreground)
set-option -g pane-border-style 'fg=#282c34'
set-option -g pane-active-border-style 'fg=#282c34'

# Command mode
set-option -g message-style 'fg=#abb2bf,bg=#282c34'

# Copy mode
set-option -w -g mode-style 'fg=#abb2bf,bg=#3b4048'

# The following seems to be needed to avoid strange highlighting of windows with
# activity (basically it disables such hl (even if present in the statusline))
set-option -g window-status-activity-style 'bold'


# Status line 
source ~/.dotfiles/tool/tmux/statusline.tmux

# Plugins
# Auto install tmux plugin manager if it is not installed
if "test ! -d ~/.tmux/plugins/tpm" \
   "run 'git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm'"

# List of plugins
set-option -g @tpm_plugins ' \
    tmux-plugins/tpm \
    tmux-plugins/tmux-copycat \
    tmux-plugins/tmux-battery \
    tmux-plugins/tmux-resurrect \
    tmux-plugins/tmux-continuum \
'

# Install plugins if not installed
set-environment -g TMUX_PLUGIN_MANAGER_PATH '$HOME/.tmux/plugins/'
if "test ! -d ~/.tmux/plugins/tmux-copycat" \
   "run '~/.tmux/plugins/tpm/bin/install_plugins'"

# Battery icons (note: these require nerd fonts)
set-option -g @batt_icon_charge_tier1 ''
set-option -g @batt_icon_charge_tier2 ''
set-option -g @batt_icon_charge_tier3 ''
set-option -g @batt_icon_charge_tier4 ''
set-option -g @batt_icon_charge_tier5 ''
set-option -g @batt_icon_charge_tier6 ''
set-option -g @batt_icon_charge_tier7 ''
set-option -g @batt_icon_charge_tier8 ''
set-option -g @batt_icon_status_charged ''
set-option -g @batt_icon_status_charging ''

# Continuum and resurrect (use C-r to restore)
set-option -g @continuum-save-interval '3'
set-option -g @resurrect-capture-pane-contents 'on'
set-option -g @resurrect-processes 'ssh mosh-client pgcli mssql-cli litecli ranger fzf'

# Extrakto
set-option -g @extrakto_split_direction "v"
set-option -g @extrakto_key "tab"
set-option -g @extrakto_split_size "15"
set-option -g @extrakto_insert_key "enter"
set-option -g @extrakto_copy_key "ctrl-y"

# Initialize TMUX plugin manager (this must be the last line of the conf file)
run-shell '~/.tmux/plugins/tpm/tpm'


# Copy to system clipboard as in vim (both with y and the default `Enter` mappings)
# macOS with iTerm2 integration
if-shell 'test "$(uname)" = "Darwin"' \
    'bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"; \
     bind -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "pbcopy"; \
     bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy"' \
    'bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "xclip -i -f -selection primary | xclip -i -selection clipboard"; \
     bind -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "xclip -i -f -selection primary | xclip -i -selection clipboard"; \
     bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "xclip -i -f -selection primary | xclip -i -selection clipboard"'

# Paste from system clipboard
# Use Cmd+V in iTerm2 or prefix+P/p in tmux
if-shell 'test "$(uname)" = "Darwin"' \
    'bind P run-shell "pbpaste | tmux load-buffer - && tmux paste-buffer"; \
     bind p run-shell "pbpaste | tmux load-buffer - && tmux paste-buffer"' \
    'bind P run-shell "xclip -o -sel clip | tmux load-buffer - && tmux paste-buffer"; \
     bind p run-shell "xclip -o -sel clip | tmux load-buffer - && tmux paste-buffer"'

# Enable clipboard integration for iTerm2
set-option -g set-clipboard on

# Allow terminal to set clipboard (iTerm2 support)
set-option -ag terminal-overrides ',*:Ms=\\E]52;c;%p2%s\\007'

# Enable clipboard integration for iTerm2
set-option -g set-clipboard on

# Allow terminal to set clipboard (iTerm2 support)
set-option -ag terminal-overrides ',*:Ms=\\E]52;c;%p2%s\\007'

# local config
if-shell "[ -f ~/.tmux.conf.local ]" 'source ~/.tmux.conf.local'











