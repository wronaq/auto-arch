if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

if [[ "$(tty)" = "/dev/tty1" ]]; then
    pgrep dwm || startx
