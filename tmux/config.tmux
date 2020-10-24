#############################
########## Bindings
#############################
# Set the prefix to `Ctrl + a` instead of `Ctrl + b`
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# Automatically set window title
set-window-option -g automatic-rename on
set-option -g set-titles on

# Prefix + / to search
bind-key / copy-mode \; send-key ?

# Setup 'v' to begin selection, just like Vim
bind-key -T copy-mode-vi 'v' send -X begin-selection

 # Setup 'y' to yank (copy), just like Vim
bind-key -T copy-mode-vi 'y' send -X copy-pipe-and-cancel "pbcopy"
bind-key -T copy-mode-vi 'V' send -X select-line
bind-key -T copy-mode-vi 'r' send -X rectangle-toggle

# Reload configuration
bind r source-file ~/.tmux.conf \; display '~/.tmux.conf sourced'


#############################
########## Settings
#############################

# Setup mouse 
set -g mouse on

# -- general -------------------------------------------------------------------
set -g default-terminal 'screen-256color' # colors!
setw -g xterm-keys on
set -s escape-time 10                     # faster command sequences
set -sg repeat-time 600                   # increase repeat timeout
set -s focus-events on


set -q -g status-utf8 on                  # expect UTF-8 (tmux < 2.2)
setw -q -g utf8 on

set -g history-limit 100000                 # boost history


# Start window and pane indices at 1.
set -g base-index 1           # start windows numbering at 1
setw -g pane-base-index 1     # make pane numbering consistent with windows


set -g display-panes-time 800 # slightly longer pane indicators display time
set -g display-time 1000      # slightly longer status messages display time

# redraw status line every 10 seconds
set -g status-interval 5 


# Length of tmux status line
set -g status-left-length 30
set -g status-right-length 150

set-option -g status "on"

# Default statusbar color
set-option -g status-style bg=colour237,fg=colour223 # bg=bg1, fg=fg1

# Default window title colors
set-window-option -g window-status-style bg=colour214,fg=colour237 # bg=yellow, fg=bg1

# Default window with an activity alert
set-window-option -g window-status-activity-style bg=colour237,fg=colour248 # bg=bg1, fg=fg3

# Active window title colors
set-window-option -g window-status-current-style bg=red,fg=colour237 # fg=bg1

# Set active pane border color
set-option -g pane-active-border-style fg=colour214

# Set inactive pane border color
set-option -g pane-border-style fg=colour239

# Message info
set-option -g message-style bg=colour239,fg=colour223 # bg=bg2, fg=fg1

# Writing commands inactive
set-option -g message-command-style bg=colour239,fg=colour223 # bg=fg3, fg=bg1

# Pane number display
set-option -g display-panes-active-colour colour1 #fg2
set-option -g display-panes-colour colour237 #bg1

# Clock
set-window-option -g clock-mode-colour colour109 #blue

# Bell
set-window-option -g window-status-bell-style bg=colour167,fg=colour235 # bg=red, fg=bg

set-option -g status-left "\
#[fg=colour7, bg=colour241]#{?client_prefix,#[bg=colour167],} ❐ #S \
#[fg=colour241, bg=colour237]#{?client_prefix,#[fg=colour167],}#{?window_zoomed_flag, 🔍,}"

set-option -g status-right "\
#[fg=colour246, bg=colour237]  %b %d %y\
#[fg=colour109]  %H:%M \
#[fg=colour248, bg=colour239]"

set-window-option -g window-status-current-format "\
#[fg=colour237, bg=colour214]\
#[fg=colour239, bg=colour214] #I* \
#[fg=colour239, bg=colour214, bold] #W \
#[fg=colour214, bg=colour237]"

set-window-option -g window-status-format "\
#[fg=colour237,bg=colour239,noitalics]\
#[fg=colour223,bg=colour239] #I \
#[fg=colour223, bg=colour239] #W \
#[fg=colour239, bg=colour237]"

# -- navigation ----------------------------------------------------------------

# create session
bind C-c new-session

# find session
bind C-f command-prompt -p find-session 'switch-client -t %%'

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
bind + run 'cut -c3- ~/.tmux.conf | sh -s _maximize_pane "#{session_name}" #D'

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


# -- urlview -------------------------------------------------------------------

bind U run "cut -c3- ~/.tmux.conf | sh -s _urlview #{pane_id}"


# -- vim-tmux-navigator -------------------------------------------

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
# -- end vim-tmux-navigator --------------------------------------------


# Setup 'v' to begin selection, just like Vim
bind-key -T copy-mode-vi 'v' send -X begin-selection

 # Setup 'y' to yank (copy), just like Vim
bind-key -T copy-mode-vi 'y' send -X copy-pipe-and-cancel "pbcopy"
bind-key -T copy-mode-vi 'V' send -X select-line
bind-key -T copy-mode-vi 'r' send -X rectangle-toggle

# List of plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-cpu'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'tmux-plugins/tmux-yank'
set -g @plugin 'tmux-plugins/tmux-online-status'

# Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
run '$HOME/.dotfiles/.tmux/plugins/tpm/tpm'
