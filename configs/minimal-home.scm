;; Minimal niri desktop for Guix on a foreign distro (written for Ubuntu 24.04).
;;
;;   guix home reconfigure configs/minimal-home.scm
;;
;; Ubuntu has to provide what needs its own PAM, udev rules or audio daemon:
;;
;;   sudo apt install swaylock brightnessctl wireplumber
;;   sudo usermod -aG video $USER
;;
;; swaylock in particular must not come from Guix here: Guix's PAM can't use
;; Ubuntu's setuid password helper, so it could never unlock the screen.
;; Firefox also comes from Ubuntu, which avoids needing the nonguix channel.
;;
;; To list niri in GDM, see minimal-niri.desktop.

(use-modules (gnu home)
             (gnu home services)
             (gnu home services gnupg)
             (gnu home services shells)
             (gnu packages)
             (gnu services)
             (guix gexp))

(home-environment
 (packages
  (specifications->packages
   (list
    ;; Niri / Wayland
    "cliphist"
    "kitty"
    "niri"
    "pavucontrol"
    "playerctl"
    "rofi"
    "swayidle"
    "waybar"
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
    "font-jetbrains-mono"
    "glibc-locales"                     ;Guix programs can't use Ubuntu's
    "htop")))

 (services
  (list
   (service home-xdg-configuration-files-service-type
            `(("niri/config.kdl" ,(local-file "minimal-niri.kdl"))
              ("waybar/config" ,(local-file "minimal-waybar.jsonc"))
              ("waybar/style.css" ,(local-file "minimal-waybar.css"))
              ("rofi-pass/config" ,(local-file "minimal-rofi-pass.conf"))))

   ;; Guix's gpg-agent has no default pinentry, so `pass' needs one set.
   (service home-gpg-agent-service-type
            (home-gpg-agent-configuration
             (pinentry-program
              (file-append (specification->package "pinentry")
                           "/bin/pinentry"))))

   ;; Guix Home takes over ~/.profile, so keep what Ubuntu's default one does.
   (simple-service 'ubuntu-profile home-shell-profile-service-type
                   (list (plain-file "ubuntu-profile" "\
if [ -n \"$BASH_VERSION\" ] && [ -f \"$HOME/.bashrc\" ]; then
    . \"$HOME/.bashrc\"
fi
[ -d \"$HOME/bin\" ] && PATH=\"$HOME/bin:$PATH\"
[ -d \"$HOME/.local/bin\" ] && PATH=\"$HOME/.local/bin:$PATH\"
"))))))
