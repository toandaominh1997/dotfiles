set -g mouse on
set -g history-limit 10000 #boost history 
# -- general -------------------------------------------------------------------
set -g default-terminal "screen-256color" # colors!


# -- display -------------------------------------------------------------------
set -g base-index 1
setw -g pane-base-index 1     # make pane numbering consistent with windows

setw -g automatic-rename on   # rename window to reflect current program
set -g renumber-windows on    # renumber windows when a window is closed

set -g set-titles on          # set terminal title


# copy and paste in tmux


# Auto resize window

set -g status-keys vi
setw -g monitor-activity on

# Reload the file with Prefix r
bind r source-file ~/.tmux.conf \; display "reloaded!"

bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
