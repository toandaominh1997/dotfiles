# Version 1 
# Reload status every second and set lengths
set-option -g status-interval 1
set-option -g status-left-length 100
set-option -g status-right-length 100

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
'#[fg=#828997,bg=#282c34,nobold]  %H:%M #[fg=#3b4048,bg=#282c34,nobold]'\
'#[fg=#abb2bf,bg=#3b4048,nobold] %Y %b %d #[fg=#d0d0d0,bg=#3b4048,nobold]'\
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


# Version 2
set -g mode-style "fg=#eee8d5,bg=#073642"

set -g message-style "fg=#eee8d5,bg=#073642"
set -g message-command-style "fg=#eee8d5,bg=#073642"

set -g pane-border-style "fg=#073642"
set -g pane-active-border-style "fg=#eee8d5"

set -g status "on"
set -g status-interval 1
set -g status-justify "left"

set -g status-style "fg=#586e75,bg=#073642"

set -g status-bg "#002b36"

set -g status-left-length "100"
set -g status-right-length "100"

set -g status-left-style NONE
set -g status-right-style NONE

set -g status-left "#[fg=#073642,bg=#eee8d5,bold] #S #[fg=#eee8d5,bg=#93a1a1,nobold,nounderscore,noitalics]#[fg=#15161E,bg=#93a1a1,bold] #(whoami) #[fg=#93a1a1,bg=#002b36]"

set -g status-right "#[fg=#586e75,bg=#002b36,nobold,nounderscore,noitalics]"\
"#[fg=#93a1a1,bg=#586e75]#[fg=#657b83,bg=#586e75,nobold,nounderscore,noitalics]"\
"#[fg=#93a1a1,bg=#657b83]#[fg=#93a1a1,bg=#657b83,nobold,nounderscore,noitalics]"\
"#[fg=#15161E,bg=#93a1a1,bold] #h "

setw -g window-status-activity-style "underscore,fg=#839496,bg=#002b36"
setw -g window-status-separator ""
setw -g window-status-style "NONE,fg=#839496,bg=#002b36"
setw -g window-status-format '#[fg=#002b36,bg=#002b36]#[default] #I  #{b:pane_current_path} #[fg=#002b36,bg=#002b36,nobold,nounderscore,noitalics]'
setw -g window-status-current-format '#[fg=#002b36,bg=#eee8d5]#[fg=#b58900,bg=#eee8d5] #I #[fg=#eee8d5,bg=#b58900] #{b:pane_current_path} #[fg=#b58900,bg=#002b36,nobold]'
