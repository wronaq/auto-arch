#!/bin/sh

### VARIABLES ###

echo -n "Install for user: "
read NAME
DOTFILESREPO="https://github.com/wronaq/auto-arch.git"
PROGSFILE="https://raw.githubusercontent.com/wronaq/auto-arch/main/progs.csv"

### ENABLE WIFI ###
echo -n "Set up a wifi connection? [Y/n] "
read SETUP
([ "$SETUP" = "Y" ] || [ "$SETUP" = "y" ] || [ "$SETUP" = "" ]) && echo -n 'Enter SSID: ' && read SSID && echo -n 'Enter password: ' && read -s PASSWORD && nmcli device wifi connect "${SSID}" password "${PASSWORD}"

### PERMISSIONS FOR WHEEL GROUP
sed -i 's|^#%wheel ALL=(ALL) NOPASSWD: ALL|%wheel ALL=(ALL) NOPASSWD: ALL|' /etc/sudoers

### FUNCTIONS ###

installpkg(){ pacman --noconfirm --needed -S "$1" >/dev/null 2>&1 ;}

error() { echo "ERROR: $1" ; exit 1;}

refreshkeys() { \
    echo "Refreshing Arch Keyring..."
    pacman --noconfirm -S archlinux-keyring >/dev/null 2>&1
    }

manualinstall() { # Installs $1 manually if not installed. Used only for AUR helper here.
    [ -f "/usr/bin/$1" ] || (
    echo "Installing \"$1\", an AUR helper..."
    cd /tmp || exit 1
    rm -rf /tmp/"$1"*
    curl -sO https://aur.archlinux.org/cgit/aur.git/snapshot/"$1".tar.gz &&
    sudo -u "$NAME" tar -xvf "$1".tar.gz >/dev/null 2>&1 &&
    cd "$1" &&
    sudo -u "$NAME" makepkg --noconfirm -si >/dev/null 2>&1 || return 1
    cd /tmp || return 1) ;}

maininstall() { # Installs all needed programs from main repo.
    echo "Installing \`$1\` ($N of $TOTAL). $1 $2"
    installpkg "$1"
    }

gitmakeinstall() {
    PROGNAME="$(basename "$1" .git)"
    DIR="/home/$NAME/.local/src/$PROGNAME"
    echo "Installing \`$PROGNAME\` ($N of $TOTAL) via \`git\` and \`make\`. $(basename "$1") $2"
    sudo -u "$NAME" git clone --depth 1 "$1" "$DIR" >/dev/null 2>&1 || { cd "$DIR" || return 1 ; sudo -u "$NAME" git pull --force origin master;}
    cd "$DIR" || exit 1
    make >/dev/null 2>&1
    make install >/dev/null 2>&1
    cd /tmp || return 1 ;}

aurinstall() { \
    echo "Installing \`$1\` ($N of $TOTAL) from the AUR. $1 $2"
    echo "$AURINSTALLED" | grep -q "^$1$" && return 1
    sudo -u "$NAME" yay -S --noconfirm "$1" >/dev/null 2>&1
    }

installationloop() { \
    ([ -f "$PROGSFILE" ] && cp "$PROGSFILE" /tmp/progs.csv) || curl -Ls "$PROGSFILE" | sed '/^#/d' > /tmp/progs.csv
    TOTAL=$(wc -l < /tmp/progs.csv)
    AURINSTALLED=$(pacman -Qqm)
    while IFS=, read -r TAG PROGRAM COMMENT; do
        N=$((N+1))
        echo "$COMMENT" | grep -q "^\".*\"$" && COMMENT="$(echo "$COMMENT" | sed "s/\(^\"\|\"$\)//g")"
        case "$TAG" in
            "A") aurinstall "$PROGRAM" "$COMMENT" ;;
            "G") gitmakeinstall "$PROGRAM" "$COMMENT" ;;
            *) maininstall "$PROGRAM" "$COMMENT" ;;
        esac
    done < /tmp/progs.csv ;}

pulldotfiles() { # Downloads a gitrepo with dotfiles
    echo "Downloading and installing config files..."
    DIR=$(mktemp -d)
    [ ! -d "$2/.config" ] && mkdir -p "$2/.config"
    [ ! -d "$2/wallpapers" ] && mkdir -p "$2/wallpapers"
    chown -R "$NAME":wheel "$DIR" "$2"
    sudo -u "$NAME" git clone --depth 1 --recursive --recurse-submodules "$1" "$DIR" >/dev/null 2>&1
    sudo -u "$NAME" cp -rfT "$DIR/configs/" "$2"
    sudo -u "$NAME" cp -f "$DIR/default_wallpaper.jpg" "$2/wallpapers"
    }

systembeepoff() { # Turn off system beep
    rmmod pcspkr >/dev/null 2>&1
    echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf ;}

### THE ACTUAL SCRIPT ###

# Refresh Arch keyrings.
refreshkeys || error "Error automatically refreshing Arch keyring. Consider doing so manually."

echo "Synchronizing system time to ensure successful and secure installation of software..."
ntpdate pl.pool.ntp.org >/dev/null 2>&1

[ -f /etc/sudoers.pacnew ] && cp /etc/sudoers.pacnew /etc/sudoers # Just in case

# Allow user to run sudo without password. Since AUR programs must be installed
# in a fakeroot environment, this is required for all builds with AUR.

# Make pacman and yay colorful and adds eye candy on the progress bar because why not.
grep -q "^Color" /etc/pacman.conf || sed -i "s/^#Color$/Color/" /etc/pacman.conf
grep -q "ILoveCandy" /etc/pacman.conf || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf

# Use all cores for compilation.
sed -i "s/-j2/-j$(nproc)/;s/^#MAKEFLAGS/MAKEFLAGS/" /etc/makepkg.conf

manualinstall yay || error "Failed to install AUR helper."

# The command that does all the installing. Reads the progs.csv file and
# installs each needed program the way required. Be sure to run this only after
# the user has been created and has priviledges to run sudo without a password
# and all build dependencies are installed.
installationloop

echo "Finally, installing \`libxft-bgra\` to enable color emoji in suckless software without crashes."
yes | sudo -u "$NAME" yay -S libxft-bgra-git >/dev/null 2>&1

# Install the dotfiles in the user's home directory
pulldotfiles "$DOTFILESREPO" "/home/$NAME"

# Most important command! Get rid of the beep!
systembeepoff

# Make zsh the default shell for the user.
chsh -s /bin/zsh "$NAME" >/dev/null 2>&1
sudo -u "$NAME" mkdir -p "/home/$NAME/.cache/zsh/"

# Tap to click
[ ! -f /etc/X11/xorg.conf.d/40-libinput.conf ] && printf 'Section "InputClass"
        Identifier "libinput touchpad catchall"
        MatchIsTouchpad "on"
        MatchDevicePath "/dev/input/event*"
        Driver "libinput"
        # Enable left mouse button by tapping
        Option "Tapping" "on"
EndSection' > /etc/X11/xorg.conf.d/40-libinput.conf

# Fix fluidsynth/pulseaudio issue.
grep -q "OTHER_OPTS='-a pulseaudio -m alsa_seq -r 48000'" /etc/conf.d/fluidsynth ||
   echo "OTHER_OPTS='-a pulseaudio -m alsa_seq -r 48000'" >> /etc/conf.d/fluidsynth

# Start/restart PulseAudio.
killall pulseaudio 2>/dev/null; sudo -u "$NAME" pulseaudio --start

# This lines, overwriting the permissions set up above and allow the user to run
# serveral important commands, `shutdown`, `reboot`, updating, etc. without a password.
sed -i 's|^%wheel ALL=(ALL) NOPASSWD: ALL|%wheel ALL=(ALL) NOPASSWD: /usr/bin/shutdown,/usr/bin/reboot,/usr/bin/systemctl suspend,/usr/bin/wifi-menu,/usr/bin/mount,/usr/bin/umount,/usr/bin/pacman -Syu,/usr/bin/pacman -Syyu,/usr/bin/packer -Syu,/usr/bin/packer -Syyu,/usr/bin/systemctl restart NetworkManager,/usr/bin/rc-service NetworkManager restart,/usr/bin/pacman -Syyu --noconfirm,/usr/bin/loadkeys,/usr/bin/yay,/usr/bin/pacman -Syyuw --noconfirm|' /etc/sudoers
sed -i 's|^#%wheel ALL=(ALL)|%wheel ALL=(ALL)|' /etc/sudoers

###############################################################################
# Cleaning
###############################################################################

# Clean orphans pkg
[ -n $(pacman -Qdt) ] && echo "No orphans to remove." || pacman -Rns $(pacman -Qdtq) --noconfirm

echo "
###############################################################################
# Done
###############################################################################
"
