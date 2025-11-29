;; This "home-environment" file can be passed to 'guix home reconfigure'
;; to reproduce the content of your profile.  This is "symbolic": it only
;; specifies package names.  To reproduce the exact same profile, you also
;; need to capture the channels being used, as returned by "guix describe".
;; See the "Replicating Guix" section in the manual.

(define-module (noonker home home-configuration))

(use-modules (gnu home)
             (gnu packages)
             (gnu services)
             (gnu home services desktop)
	     (gnu home services sound)
             (guix gexp)
             (gnu home services shells))

(define pipewire-config
  (home-pipewire-configuration
   (enable-pulseaudio? #t)))

(home-environment
 ;; Below is the list of packages that will show up in your
 ;; Home profile, under ~/.guix-home/profile.
 (packages (specifications->packages (list "p7zip"
					   "unzip"
					   "kicad"
					   "texlive"
					   "inkscape"
                                           "radare2"
                                           "python"
                                           "curl"
                                           "rsync"
                                           "the-silver-searcher"
                                           "passt"
                                           "podman-compose"
                                           "podman"
                                           "slirp4netns"
                                           "distrobox"
                                           "gcc-toolchain"
                                           "cairo"
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
                                           "emacs-next"
                                           "signal-desktop"
                                           "firefox"
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
					   "tmux"
					   "direnv"
					   "screen"
					   "bind:utils"
					   "alsa-utils"
					   "qpwgraph"
;;					   "lua"
					   ;; Guile Hacking
					   "guile"
					   "emacs-geiser"
					   "emacs-geiser-guile"
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
					   )))
 

  ;; Below is the list of Home services.  To search for available
  ;; services, run 'guix home search KEYWORD' in a terminal.
  (services
   (list
    (service home-pipewire-service-type pipewire-config)
    (service home-dbus-service-type)
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
