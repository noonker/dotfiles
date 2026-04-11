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
             (gnu home services shells))

(define pipewire-config
  (home-pipewire-configuration
   (enable-pulseaudio? #t)))


(define sway-config
  (map (lambda (str)
         (string-append str "\n"))
       (list
        "set $mod Mod4"
        "include \"~/.config/sway/before-config\""
        "bindsym $mod+space exec fuzzel -w 50 -x 8 -y 8 -r 3 -b 232635ff -t A6Accdff -s A6Accdff -S 232635ff -C c792eacc -m c792eacc -f \"Comic Code:weight=light:size=10\""
        "exec mako --border-radius=2 --font=\"JetBrains Mono 8\" --max-visible=5 --outer-margin=5 --margin=3 --background=\"#1c1f26\" --border-color=\"#89AAEB\" --border-size=1 --default-timeout=7000"
        "exec nm-applet --indicator"
        "exec emacs"
        "include \"~/.config/sway/after-config\"")))

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
                                           "rsync"
                                           "the-silver-searcher"
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
					   "fuzzel"
					   "grim"
					   "mako"
					   "rofi"
					   "kitty"
					   "htop"
					   "s-tui"
					   "grimshot"
					   "waybar"
					   "network-manager-applet"

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
   (service home-xdg-configuration-files-service-type
            `(("sway/config" ,(apply mixed-text-file (cons "sway-config" sway-config)))))
   (simple-service 'containers-config
		   home-xdg-configuration-files-service-type
		   `(("containers/registries.conf"
		      ,(plain-file "registries.conf"
				   "unqualified-search-registries = [\"docker.io\", \"quay.io\", \"myregistry.example.com\"]
[[registry]]
location = \"myregistry.example.com\"
insecure = true
blocked = false
"))
		     ("containers/policy.json"
		      ,(plain-file "policy.json"
				   "{\n  \"default\": [ { \"type\": \"insecureAcceptAnything\" } ]\n}\n"))))
   
   (service home-bash-service-type
            (home-bash-configuration
             (aliases '(("grep" . "grep --color=auto") ("ll" . "ls -l")
                        ("ls" . "ls -p --color=auto")))
	     (environment-variables '(("PATH" . "$PATH:$HOME/.local/bin")))
             (bashrc (list (local-file
                            "/home/person/git/dotfiles/guix/noonker/home/.bashrc"
                            "bashrc")))
             (bash-profile (list (local-file
                                  "/home/person/git/dotfiles/guix/noonker/home/.bash_profile"
                                  "bash_profile")))))
   )))

