if [ -f ~/.zshrc ]; then
    source ~/.zshrc
fi

if [[ "$(tty)" = "/dev/tty1" ]]; then
    pgrep dwm || startx
fi
