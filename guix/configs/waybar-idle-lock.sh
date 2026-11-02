#!/bin/sh
# Screen-sleep lock for the waybar brightness widget.
#
# Sleep is inhibited by simply not running swayidle, so the lock icon
# reflects reality even if swayidle dies on its own.
#   start  - launch swayidle (niri calls this at startup)
#   toggle - stop swayidle if running, else start it; refresh waybar
#   status - waybar custom module: print something while inhibited, which shows its icon

start() {
    setsid -f swayidle -w \
        timeout 180 "$HOME/bin/theme-lock" \
        timeout 300 'niri msg action power-off-monitors' \
            resume 'niri msg action power-on-monitors' \
        before-sleep "$HOME/bin/theme-lock" >/dev/null 2>&1
}

case "$1" in
start)
    start ;;
toggle)
    if pgrep -x swayidle >/dev/null; then pkill -x swayidle; else start; fi
    pkill -RTMIN+9 waybar ;;
status)
    pgrep -x swayidle >/dev/null || echo on ;;
esac
