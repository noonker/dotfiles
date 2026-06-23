;; This "home-environment" file can be passed to 'guix home reconfigure'
;; to reproduce the content of your profile.  This is "symbolic": it only
;; specifies package names.  To reproduce the exact same profile, you also
;; need to capture the channels being used, as returned by "guix describe".
;; See the "Replicating Guix" section in the manual.

(define-module (noonker home home-configuration))

(use-modules (gnu home)
	     (noonker home emacs)
	     (noonker home ollama)
	     (noonker home hydroxide)
	     (noonker home pw-autoconnect)
	     (noonker home git-repos)
	     (noonker packages wine)
	     (noonker packages serialosc)
	     (noonker packages renoise)
	     (noonker packages tidalcycles)
	     (noonker packages sc3-plugins)
	     (gnu packages)
	     (gnu services)
	     (gnu home services)
	     (gnu home services xdg)
	     (gnu home services desktop)
	     (gnu home services sound)
	     (gnu home services gnupg)
	     (gnu home services shells)
	     (guix packages)
	     (guix build-system font)
	     (guix gexp)
	     ;; For ~/bin helper
	     (ice-9 ftw)
	     (ice-9 regex)
	     (srfi srfi-1)
	     )

(define pipewire-config
  (home-pipewire-configuration
   (enable-pulseaudio? #t)))

;; Font
(define my-comic-code-font
  (package
    (name "font-comic-code")
    (version "1.0")
    (source (local-file "/home/person/.password-store/Comic Code/OTF"
                        #:recursive? #t))
    (build-system font-build-system)
    (synopsis "Comic Code font")
    (description "Comic Code monospace font.")
    (home-page "")
    (license #f)))

(define wine-packages
  (list wine-9.21-staging wine64-9.21-staging))

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
 (packages
  (append
   (list serialosc renoise tidalcycles)
   (specifications->packages (list
					;; Niri / Wayland
					"blueman"
					"brightnessctl"
					"cliphist"
					"grim"
					"kitty"
					"mako"
					"network-manager-applet"
					"niri"
					"pavucontrol"
					"playerctl"
					"polkit-gnome"
					"rofi"
					"rofi-pass"
					"slurp"
					"swayidle"
					"swaylock"
					"waybar"
					"wl-clipboard"
					"wlsunset"
					"wtype"
					"xwayland-satellite"
					"yad"

					;; CLI
					"7zip"
					"coreutils"
					"curl"
					"daikichi"
					"direnv"
					"file"
					"fortunes-jkirchartz"
					"htop"
					"jq"
					"rsync"
					"s-tui"
					"screen"
					"the-silver-searcher"
					"tmux"
					"unzip"
					"vim"

					;; Build tools
					"autoconf"
					"automake"
					"clang"
					"cmake"
					"gcc-toolchain"
					"libtool"
					"make"
					"pkg-config"

					;; Programming
					"git"
					"node"
					"perl"
					"python"
					"python-wrapper"

					;; Clojure
					"babashka"
					"clojure"
					"clojure-tools"
					"openjdk:jdk"

					;; Guile
					"emacs-geiser"
					"emacs-geiser-guile"
					"guile"

					;; Emacs
					"emacs-pgtk"

					;; Radio / SDR
					"gnuradio"
					"gr-osmosdr"
					;; Needed to build gr-bladeRF
					"boost"
					"glib:bin"
					"gmp"
					"pybind11"
					"spdlog"
					"volk"

					;; Audio
					"alsa-utils"
					"carla"
					"liblo"          ;oscsend, oscdump
					"qpwgraph"
					"supercollider"
					"winetricks"
					"wine64"
					"yabridge"
					"yabridgectl"

					;; Runtime libs for foreign VST/LV2/CLAP
					;; binaries (rpath'd in by ~/bin/patch-vsts)
					"alsa-lib"
					;;"cairo"
					"dbus"
					"fontconfig"
					"freetype"
					"gdk-pixbuf"
					;;"glib"
					"gtk+"
					"libglvnd"
					"libice"          ;Vital
					"libsm"           ;Vital
					"libx11"
					"libxcb"
					"libxcursor"
					"libxext"
					"libxinerama"
					"libxkbcommon"
					"libxrandr"
					"mesa"
					"pango"
					"zlib"

					;; Media
					"ffmpeg"
					"imagemagick"
					"mpv"
					"yt-dlp"

					;; Creative
					"blender"
					"inkscape"
					"kicad"
					"lilypond"
					"texlive-scheme-full"

					;; Networking
					"bind:utils"
					"bluez"
					"openssh"

					;; Containers
					"distrobox"
					"passt"
					"podman"
					"podman-compose"
					"slirp4netns"

					;; Security / Passwords
					"pass-otp"
					"password-store"
					"pinentry"
					"pwgen"
					"radare2"

					;; Fonts
					"font-awesome"
					"font-jetbrains-mono"
					"font-liberation"

					;; Appearance
					"adwaita-icon-theme"
					"gnome-themes-extra"
					"gnome-tweaks"

					;; Flatpak / XDG
					"flatpak"
					"poppler"
					"shared-mime-info"
					"xdg-dbus-proxy"
					"xdg-desktop-portal"
					"xdg-desktop-portal-gnome"
					"xdg-desktop-portal-gtk"
					"xdg-utils"

					;; Browser
					"firefox"
					"icecat"

					;; Communication
					"signal-desktop"

					;; VPN
					"proton-vpn-cli"

					;; Services
					"hydroxide"
					"ollama-linux-amd64"

					;; Virtualization
					"kubectl"
					"qemu"
					"remmina"
					))))


 ;; Below is the list of Home services.  To search for available
 ;; services, run 'guix home search KEYWORD' in a terminal.
 (services
  (list
   (service home-pipewire-service-type pipewire-config)
   (service home-dbus-service-type)
   emacs-daemon-service
   ollama-daemon-service
   hydroxide-daemon-service
   pw-autoconnect-daemon-service
   (simple-service 'my-font-packages
                   home-profile-service-type
                   (list my-comic-code-font))
   (simple-service 'my-bins
                   home-files-service-type
                   (dotfiles-bin-directory
                    "/home/person/git/dotfiles/bin"
                    "bin"))
   (simple-service 'my-desktop-overrides
                   home-files-service-type
                   (dotfiles-bin-directory
                    "/home/person/git/dotfiles/guix/configs/applications"
                    ".local/share/applications"))
   (simple-service 'my-dotfiles
                   home-files-service-type
                   (list
                    `(".tmux.conf"  ,(local-file (dotfile "guix/configs/tmux.conf")))
                    `(".npmrc"      ,(local-file (dotfile "guix/configs/npmrc")))
                    ))
   (service home-git-repos-service-type
         (home-git-repos-configuration
          (directory "~/git")
          (repos '(("dotfiles"  . "git@github.com:noonker/dotfiles.git")
                   ("hunting-mode"   . "git@github.com:noonker/hunting-mode.git")
                   ))))
   (service home-xdg-mime-applications-service-type
            (home-xdg-mime-applications-configuration
             (default '((x-scheme-handler/http . firefox.desktop)
                        (x-scheme-handler/https . firefox.desktop)
                        (x-scheme-handler/about . firefox.desktop)
                        (x-scheme-handler/unknown . firefox.desktop)
                        (text/html . firefox.desktop)
                        (application/xhtml+xml . firefox.desktop)))))
   (service home-xdg-configuration-files-service-type
            `(
	      ("niri/config.kdl" ,(local-file (dotfile "guix/configs/niri.kdl")))
	      ("rofi/config.rasi" ,(local-file (dotfile "guix/configs/config.rasi")))
	      ("rofi-pass/config" ,(local-file (dotfile "guix/configs/rofi-pass.conf")))
	      ("waybar/config" ,(local-file (dotfile "guix/configs/waybar.conf")))
	      ("waybar/style.css" ,(local-file (dotfile "guix/configs/waybar_style.css")))
	      ("containers/registries.conf" ,(local-file (dotfile "guix/configs/podman_registries.conf")))
	      ("containers/policy.json" ,(local-file (dotfile "guix/configs/podman_policy.json")))
	      ("shaders/background.frag" ,(local-file (dotfile "guix/configs/background.frag")))
	      ("guix/channels.scm" ,(local-file (dotfile "guix/configs/guix_channels")))
	      ("xdg-desktop-portal/portals.conf" ,(local-file (dotfile "guix/configs/portals.conf")))
	      ("kitty/kitty.conf" ,(local-file (dotfile "guix/configs/kitty.conf")))
	      ("SuperCollider/startup.scd" ,(local-file (dotfile "guix/configs/supercollider-startup.scd")))
	      ))
   ;; Expose sc3-plugins to scsynth/sclang by symlinking the package's
   ;; SC3plugins tree into the user's SuperCollider Extensions directory,
   ;; which both processes scan unconditionally.
   (simple-service 'my-sc-extensions
                   home-files-service-type
                   (list
                    `(".local/share/SuperCollider/Extensions/SC3plugins"
                      ,(file-append sc3-plugins
                                    "/share/SuperCollider/Extensions/SC3plugins"))))
   (service home-gpg-agent-service-type
            (home-gpg-agent-configuration
             (pinentry-program
              (file-append (specification->package "pinentry") "/bin/pinentry"))
             (default-cache-ttl 14400)
             (max-cache-ttl 14400)))
   ;; Written to ~/.profile so they're picked up by the graphical
   ;; session (Niri via the DM) and non-login shells, not just
   ;; bash login shells.
   (simple-service 'my-env-vars
                   home-environment-variables-service-type
                   '(("EDITOR" . "emacsclient -c")
                     ("VISUAL" . "emacsclient -c")
                     ("ALTERNATE_EDITOR" . "vim")
                     ("XCURSOR_SIZE" . "24")
                     ("XDG_CURRENT_DESKTOP" . "niri")
                     ("XDG_SESSION_TYPE" . "wayland")
		     ("MOZ_ENABLE_WAYLAND" . "1")
                     ("ROFI_MEDIA_PLAYER" . "mpv")
                     ("XDG_DATA_DIRS" . "$HOME/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:$XDG_DATA_DIRS")
                     ;; Make pipewire's libjack shim win over the real libjack
                     ;; so SuperCollider (and other JACK clients) route through
                     ;; pipewire without needing the `pw-jack` wrapper.
                     ("LD_LIBRARY_PATH" . "$HOME/.guix-home/profile/lib/pipewire-0.3/jack${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}")
                     ("PATH" . "$HOME/bin:$HOME/.npm-global/bin:$PATH")))
   (service home-bash-service-type
            (home-bash-configuration
             (aliases '(("grep" . "grep --color=auto") ("ll" . "ls -l")
                        ("ls" . "ls -p --color=auto")))
             (bashrc (list (local-file
                            "/home/person/git/dotfiles/guix/noonker/home/.bashrc"
                            "bashrc")))
             (bash-profile (list (local-file
                                  "/home/person/git/dotfiles/guix/noonker/home/.bash_profile"
                                  "bash_profile")))))
   )))
