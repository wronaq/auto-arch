#!/usr/bin/env bash

echo -e "\nInstalling Base System\n"

PKGS=(

    # --- XORG Display Rendering
        'xorg'                  # Base Package
        'xorg-apps'             # Xorg apps group
        'xorg-xinit'            # Xorg init
        'libx11'                # Xorg client-side
        'libxinerama'           # Many displays
        'libxft'                # Basic fonts
        'webkit2gtk'            # Webkit

    # --- Setup Desktop
        'picom'                 # Translucent Windows
        'nitrogen'              # Set Wallpaper

    # --- Audio
        'alsa-utils'        # Advanced Linux Sound Architecture (ALSA) Components https://alsa.opensrc.org/
        'alsa-plugins'      # ALSA plugins

    # --- Networking Setup
        'wpa_supplicant'            # Key negotiation for WPA wireless networks

)

for PKG in "${PKGS[@]}"; do
    echo "INSTALLING: ${PKG}"
    sudo pacman -S "$PKG" --noconfirm --needed
done


echo "INSTALLING dwm, dmenu and st"
cp suckless ~/suckless
cd ~/suckless/dwm && sudo make clean install
cd ../dmenu && sudo make clean install
cd ../st && sudo make clean install


echo -e "\nDone!\n"
