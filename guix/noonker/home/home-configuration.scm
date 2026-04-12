;; This "home-environment" file can be passed to 'guix home reconfigure'
;; to reproduce the content of your profile.  This is "symbolic": it only
;; specifies package names.  To reproduce the exact same profile, you also
;; need to capture the channels being used, as returned by "guix describe".
;; See the "Replicating Guix" section in the manual.

(define-module (noonker home home-configuration))

(use-modules (gnu home)
             (gnu packages)
             (gnu services)
	     (gnu home services)
	     (gnu home services xdg)
	     (gnu home services desktop)
	     (gnu home services sound)
             (guix gexp)
             (gnu home services shells)
	     ;; For ~/bin helper
	     (ice-9 ftw)
	     (ice-9 regex)
	     )

(define pipewire-config
  (home-pipewire-configuration
   (enable-pulseaudio? #t)))


(define %dotfiles-dir "/home/person/git/dotfiles/")

;; Helper to build paths relative to dotfiles
(define (dotfile path)
  (string-append %dotfiles-dir "/" path))

(define (dotfiles-bin-directory source-dir dest-prefix)
  (let ((files (scandir source-dir
                        (lambda (f) (not (member f '("." "..")))))))
    (map (lambda (f)
           (list (string-append dest-prefix "/" f)
                 (local-file (string-append source-dir "/" f)
                             f
                             #:recursive? #t)))
         (or files '()))))

(home-environment
 ;; Below is the list of packages that will show up in your
 ;; Home profile, under ~/.guix-home/profile.
 (packages (specifications->packages (list "7zip"
					   "unzip"
					   "kicad"
					   ;; "texlive-scheme-full"
					   "inkscape"
                                           "radare2"
                                           "python"
					   "python-wrapper"
                                           "curl"
					   "bluez"
                                           "rsync"
                                           "the-silver-searcher"
					   "brightnessctl"
                                           "passt"
                                           "podman-compose"
                                           "podman"
                                           "slirp4netns"
                                           "distrobox"
                                           "gcc-toolchain"
                                           ;; "cairo"
                                           "poppler"
                                           "node"
                                           "clang"
                                           "perl"
                                           "libtool"
                                           "pkg-config"
                                           "qemu"
                                           "automake"
                                           "autoconf"
                                           "cmake"
                                           "make"
                                           "openssh"
                                           "git"
					   "mpv"
					   "imagemagick"
                                           "nss-certs"
                                           "kubectl"
                                           "font-jetbrains-mono"
                                           "pinentry"
					   "gnuradio"
                                           "file"
                                           "gnome-tweaks"
                                           "password-store"
                                           "flatpak"
					   "emacs-pgtk"
                                           "signal-desktop"
					   "clojure"
					   "babashka"
					   "coreutils"
					   "openjdk"
					   "clojure-tools"
					   "remmina"
					   "blender"
					   "supercollider"
					   "carla"
					   "wine64"
					   "direnv"
					   "screen"
					   "bind:utils"
					   "alsa-utils"
					   "qpwgraph"
					   ;; "lua"
					   ;; Guile Hacking
					   "guile"
					   "emacs-geiser"
					   "emacs-geiser-guile"

					   ;; Cli
					   "tmux"

					   ;; Radio
					   "gnuradio"

					   ;; Needed to build gr-bladeRF
					   "spdlog"
					   "gmp"
					   "boost"
					   "volk"
					   "pybind11"
					   "gr-osmosdr"
					   "mako"
					   "glib:bin"
					   "yabridgectl"

					   ;; Sway
					   "sway"
					   "shaderbg"
					   "swayidle"
					   "swaylock"
					   "grim"
					   "mako"
					   "rofi"
					   "kitty"
					   "htop"
					   "s-tui"
					   "grimshot"
					   "waybar"
					   "cliphist"
					   "grim"
					   "rofi-pass"
					   "slurp"
					   "wtype"
					   "pwgen"
					   "pass-otp"
					   "wl-clipboard"
					   "network-manager-applet"
					   "jq"

					   ;; Browser
					   "icecat"
					   
					   ;; Compatibility for older Xorg applications
					   "xorg-server-xwayland"

					   ;; Flatpak and XDG utilities
					   "xdg-utils" ;; For xdg-open, etc
					   "xdg-dbus-proxy"
					   "shared-mime-info"

					   ;; Appearance
					   "gnome-themes-extra"
					   "adwaita-icon-theme"

					   ;; Fonts
					   "font-jetbrains-mono"
					   "font-liberation"
					   "font-awesome"
					   )))


 ;; Below is the list of Home services.  To search for available
 ;; services, run 'guix home search KEYWORD' in a terminal.
 (services
  (list
   (service home-pipewire-service-type pipewire-config)
   (service home-dbus-service-type)
   (simple-service 'my-bins
                   home-files-service-type
                   (dotfiles-bin-directory
                    "/home/person/git/dotfiles/bin"
                    "bin"))
   (simple-service 'my-dotfiles
                   home-files-service-type
                   (list
                    `(".tmux.conf"  ,(local-file (dotfile "guix/configs/tmux.conf")))
                    ))
   (service home-xdg-configuration-files-service-type
            `(
	      ("sway/config" ,(local-file (dotfile "guix/configs/sway.conf")))
	      ("rofi/config.rasi" ,(local-file (dotfile "guix/configs/config.rasi")))
	      ("rofi-pass/config" ,(local-file (dotfile "guix/configs/rofi-pass.conf")))
	      ("waybar/config" ,(local-file (dotfile "guix/configs/waybar.conf")))
	      ("waybar/style.css" ,(local-file (dotfile "guix/configs/waybar_style.css")))
	      ("containers/registries.conf" ,(local-file (dotfile "guix/configs/podman_registries.conf")))
	      ("containers/policy.json" ,(local-file (dotfile "guix/configs/podman_policy.json")))
	      ("shaders/background.frag" ,(local-file (dotfile "guix/configs/background.frag")))
	      ))
   (service home-bash-service-type
            (home-bash-configuration
             (aliases '(("grep" . "grep --color=auto") ("ll" . "ls -l")
                        ("ls" . "ls -p --color=auto")))
	     (environment-variables '(
				      ("PATH" . "$PATH:$HOME/.local/bin")
				      ("XCURSOR_SIZE" . "24")
				      ))
             (bashrc (list (local-file
                            "/home/person/git/dotfiles/guix/noonker/home/.bashrc"
                            "bashrc")))
             (bash-profile (list (local-file
                                  "/home/person/git/dotfiles/guix/noonker/home/.bash_profile"
                                  "bash_profile")))))
   )))

