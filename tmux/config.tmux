# Set the prefix to `Ctrl + a` instead of `Ctrl + b`
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# Setup mouse 
set -g mouse on

# increase repeat timeout
set -sg repeat-time 600


# Automatically set window title
set-window-option -g automatic-rename on
set-option -g set-titles on
set-option -g set-titles-string "#{session_name} - #W"

# Don't add delay when pressing meta or escape keys
set-option -s escape-time 10

# Use vim mode in copy mode
set-option -w -g mode-keys vi

# Don't show `Activity in window N` message but do send a visual highlight bell
set-option -g visual-activity off
set-option -w -g monitor-activity on

# Send focus events
set-option -g focus-events on

# Rather than constraining window size to the maximum size of any client
# connected to the *session*, constrain window size to the maximum size of any
# client connected to *that window*
set-option -w -g aggressive-resize on

# Use bash in interactive (i.e non-login) mode as default shell/command
set-option -g default-command $SHELL

# Restore original C-l mapping (clear screen)
bind-key C-l send-keys 'C-l'

# Split pane using v and h (in the same directory from where they are called)
# For horizontal splits we automatically set the size to rougly 12 lines
unbind-key '"'
unbind-key %
bind-key v split-window -h -c "#{pane_current_path}"
bind-key s split-window -v -c "#{pane_current_path}"


# pane navigation
bind-key -r h select-pane -L  # move left
bind-key -r j select-pane -D  # move down
bind-key -r k select-pane -U  # move up
bind-key -r l select-pane -R  # move right
bind-key > swap-pane -D       # swap current pane with the next one
bind-key < swap-pane -U       # swap current pane with the previous one
# Increase or decrease pane height with h,j,k and l (the -r flag makes it
# repeatable i.e no need to press prefix key again and again)
bind-key -r J resize-pane -D 3
bind-key -r K resize-pane -U 3
bind-key -r H resize-pane -L 3
bind-key -r L resize-pane -R 3
bind-key L next-layout
bind-key = select-layout -E

# Rename window
#bind-key r command-prompt 'rename-window %%'

# Move windows
bind-key -r C-h swap-window -d -t -1
bind-key -r C-l swap-window -d -t +1

# Choose window (window tree navigation)
bind-key w choose-window

# Pane movement (merge and break)
bind-key m choose-window "join-pane -v -s "%%""  # horizontal merge
bind-key C-b break-pane

# From here on we set vim copy bindings (note: we set the insert and command
# mode mappings directly in our bash profile!)
# Go the beginning and end of line in copy mode
bind-key -Tcopy-mode-vi H send -X start-of-line
bind-key -Tcopy-mode-vi L send -X end-of-line\; send -X cursor-left

# Do visual and block selection as in vim (for block selection we need to press
# C-v + space and then start our selection)
unbind-key -Tcopy-mode-vi v
bind-key -Tcopy-mode-vi v send -X begin-selection
bind-key -Tcopy-mode-vi 'C-v' send -X rectangle-toggle
bind-key -Tcopy-mode-vi V send -X select-line\; send -X cursor-left

# Unbind Enter since we rebind it for copying
unbind-key -Tcopy-mode-vi Enter

# Smart pane switching with awareness of Vim splits.
# See: https://github.com/christoomey/vim-tmux-navigator
is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
    | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
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

# Colors 

# Note: this terminfo comes with ncurses (it is needed for colored undecurl to
# work). It should be located at: /usr/share/terminfo/t/tmux-256color
# If it isn't reinstall ncurses
set-option -g default-terminal "tmux-256color"

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

# Reload status every second and set lengths
set-option -g status-interval 1
set-option -g status-left-length 32
set-option -g status-right-length 156

# Background and foreground colors
set-option -g status-fg '#abb2bf'
set-option -g status-bg '#282c34'

# Actually set the statusline (consistent with vim and airline)
set-option -g status-left \
'#{?client_prefix,#[fg=#24272e]#[bg=#98c379]#[bold] T '\
'#[fg=#98c379]#[bg=#d0d0d0]#[nobold]#[fg=#282c34]#[bg=#d0d0d0]#[bold],'\
'#[fg=#282c34]#[bg=#d0d0d0]#[bold]} #S '\
'#{?#{==:#I,1},#[fg=#d0d0d0]#[bg=#61afef],#[fg=#d0d0d0]#[bg=#282c34]}'

set-option -g status-right \
'#[fg=#828997,bg=#282c34,nobold]#{battery_icon} #{battery_percentage} '\
'#[fg=#828997,bg=#282c34,nobold]'\
'#[fg=#828997,bg=#282c34,nobold]  %H:%M #[fg=#3b4048,bg=#282c34,nobold]'\
'#[fg=#abb2bf,bg=#3b4048,nobold] %d %b %Y #[fg=#d0d0d0,bg=#3b4048,nobold]'\
'#[fg=#282c34,bg=#d0d0d0,bold] #h '

set-option -g window-status-current-format \
'#{?#{==:#I,1},,#[fg=#282c34]#[bg=#61afef]}'\
'#[fg=#24272e,bg=#61afef,noreverse,bold] #I:#W '\
'#{?window_zoomed_flag,#[bold] ,}#[fg=#61afef,bg=#282c34,nobold]'

set-option -g window-status-format \
'#{?window_bell_flag,'\
'#[fg=#e06c75]#[bg=#282c34]#[nobold]'\
'#[fg=#e06c75]#[bg=#282c34]#[bold] #I:#W '\
'#[fg=#282c34]#[bg=#e06c75]#[nobold],'\
'#[fg=#abb2bf]#[bg=#282c34]#[nobold] #I:#W }'

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

# Initialize TMUX plugin manager (this must be the last line of the conf file)
run-shell '~/.tmux/plugins/tpm/tpm'




















# Reload configuration
bind r source-file ~/.tmux.conf \; display '~/.tmux.conf sourced'



