;; This "home-environment" file can be passed to 'guix home reconfigure'
;; to reproduce the content of your profile.  This is "symbolic": it only
;; specifies package names.  To reproduce the exact same profile, you also
;; need to capture the channels being used, as returned by "guix describe".
;; See the "Replicating Guix" section in the manual.

(use-modules (gnu home)
             (gnu packages)
             (gnu services)
             (guix gexp)
             (gnu home services shells))

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
                                           "libpng"
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
					   "ollama-linux-amd64"
					   "carla"
					   "wine64"
					   "tmux"
					   "alsa-utils"
					   )))
 

  ;; Below is the list of Home services.  To search for available
  ;; services, run 'guix home search KEYWORD' in a terminal.
  (services
   (list (service home-bash-service-type
                  (home-bash-configuration
                   (aliases '(("grep" . "grep --color=auto") ("ll" . "ls -l")
                              ("ls" . "ls -p --color=auto")))
		   (environment-variables '(("PATH" . "$PATH:$HOME/.local/bin")))
                   (bashrc (list (local-file
                                  "/home/person/git/dotfiles/guix/noonker/home/.bashrc"
                                  "bashrc")))
                   (bash-profile (list (local-file
                                        "/home/person/git/dotfiles/guix/noonker/home/.bash_profile"
                                        "bash_profile"))))))))
