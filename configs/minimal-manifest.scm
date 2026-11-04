;; Packages for the minimal desktop.
;; guix package -m minimal-manifest.scm
;; "firefox" comes from the nonguix channel; without that channel, remove it
;; and point Mod+Backslash in minimal-niri.kdl at another browser.

(specifications->manifest
 (list
  ;; Niri / Wayland
  "brightnessctl"
  "cliphist"
  "kitty"
  "niri"
  "pavucontrol"
  "playerctl"
  "rofi"
  "swayidle"
  "swaylock"
  "waybar"
  "wireplumber"
  "wl-clipboard"
  "xwayland-satellite"

  ;; Password store, for Mod+P
  "password-store"
  "rofi-pass"
  "wtype"

  ;; Emacs
  "emacs-geiser"
  "emacs-geiser-guile"
  "emacs-pgtk"
  "guile"

  ;; Everything else
  "firefox"
  "font-jetbrains-mono"
  "htop"))
