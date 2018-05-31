# Merge in Xresources
if [ -f "$HOME/.Xresources" ]; then
  xrdb -merge "$HOME/.Xresources"
fi

# Source all files in xinitrc.d, if present
if [ -d /etc/X11/xinit/xinitrc.d]; then
  for f in /etc/X11/xinit/xinitrc.d/?*.sh; do
    if [ -x "$f" ]; then
      . "$f"
    fi
  done
fi

if [ "$(cat /sys/class/dmi/id/product_name)" = "XPS 13 9370" ]; then
  touchpad="DELL07E6:00 06CB:76AF Touchpad"
  xinput set-prop "$touchpad" "libinput Tapping Enabled" 1
  xinput set-prop "$touchpad" "libinput Natural Scrolling Enabled" 1
fi

xset r rate 200 30
exec i3
