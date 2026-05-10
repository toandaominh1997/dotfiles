# One Dark theme — consistent with vim/airline
#
# Palette (edit here, search-replace below to retheme):
#   bg          #282c34   bg-alt      #3b4048
#   fg          #abb2bf   fg-mute     #828997
#   accent      #61afef   accent-on   #d0d0d0
#   ok          #98c379   err         #e06c75
#   text-dark   #24272e

set-option -g status-interval 5
set-option -g status-left-length 100
set-option -g status-right-length 100

# Background and foreground colors
set-option -g status-fg '#abb2bf'
set-option -g status-bg '#282c34'

# Status left: session name with prefix indicator
set-option -g status-left \
'#{?client_prefix,#[fg=#24272e]#[bg=#98c379]#[bold] T '\
'#[fg=#98c379]#[bg=#d0d0d0]#[nobold]#[fg=#282c34]#[bg=#d0d0d0]#[bold],'\
'#[fg=#282c34]#[bg=#d0d0d0]#[bold]} #S '\
'#{?#{==:#I,1},#[fg=#d0d0d0]#[bg=#61afef],#[fg=#d0d0d0]#[bg=#282c34]}'

# Status right: net + battery + clock + date + host
set-option -g status-right \
'#[fg=#828997,bg=#282c34,nobold]#{online_status} '\
'#[fg=#828997,bg=#282c34,nobold]#{battery_icon} #{battery_percentage} '\
'#[fg=#828997,bg=#282c34,nobold]  %H:%M #[fg=#3b4048,bg=#282c34,nobold]'\
'#[fg=#abb2bf,bg=#3b4048,nobold] %Y %b %d #[fg=#d0d0d0,bg=#3b4048,nobold]'\
'#[fg=#282c34,bg=#d0d0d0,bold] #h '

set-option -g window-status-current-format \
'#{?#{==:#I,1},,#[fg=#282c34]#[bg=#61afef]}'\
'#[fg=#24272e,bg=#61afef,noreverse,bold] #I:#W '\
'#{?window_zoomed_flag,#[bold] ,}#[fg=#61afef,bg=#282c34,nobold]'

set-option -g window-status-format \
'#{?window_bell_flag,'\
'#[fg=#e06c75]#[bg=#282c34]#[nobold]'\
'#[fg=#e06c75]#[bg=#282c34]#[bold] #I:#W '\
'#[fg=#282c34]#[bg=#e06c75]#[nobold],'\
'#[fg=#abb2bf]#[bg=#282c34]#[nobold] #I:#W }'
