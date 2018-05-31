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

xset r rate 200 30
exec i3
