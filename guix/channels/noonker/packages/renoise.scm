;; Adapted from https://github.com/.../yumi/packages/renoise.scm
;; Packages the locally-downloaded registered Renoise tarball
;; (rather than fetching the demo from files.renoise.com).

(define-module (noonker packages renoise)
  #:use-module (gnu packages linux)        ; alsa-lib
  #:use-module (gnu packages xorg)         ; libx11, libxext
  #:use-module (gnu packages gcc)          ; gcc:lib
  #:use-module (gnu packages mp3)          ; mpg123
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module ((nonguix licenses) #:prefix license:)
  #:use-module (nonguix build-system binary)
  #:export (renoise))

(define %renoise-tarball
  (string-append (getenv "HOME")
                 "/Documents/rns_354_linux_x86_64.tar.gz"))

(define-public renoise
  (package
    (name "renoise")
    (version "3.5.4")
    (source (local-file %renoise-tarball))
    (build-system binary-build-system)
    (arguments
     (list
      #:strip-binaries? #f
      #:patchelf-plan
      #~(list (list "renoise"
                    '("libc" "gcc" "alsa-lib" "libx11" "libxext"))
              (list "Resources/AudioPluginServer_x86_64"
                    '("libc" "gcc" "alsa-lib" "libx11" "libxext")))
      #:phases
      #~(modify-phases %standard-phases
          (replace 'install
            (lambda* (#:key outputs #:allow-other-keys)
              (let* ((out     (assoc-ref outputs "out"))
                     (share   (string-append out "/share"))
                     (bin     (string-append out "/bin"))
                     (version #$version))

                (define (find-and-chmod path type name-regex ch-perm)
                  (for-each (lambda (f) (chmod f ch-perm))
                            (find-files
                             path
                             (lambda (file stat)
                               (and
                                (cond ((equal? "d" type)
                                       (directory-exists? file))
                                      ((equal? "f" type)
                                       (not (directory-exists? file)))
                                      (t (error "invalid find type")))
                                ((file-name-predicate name-regex) file stat)))
                             #:directories? #t
                             #:fail-on-error? #t)))

                (find-and-chmod "." "d" ".*" #o755)
                (find-and-chmod "." "f" ".*" #o644)
                (find-and-chmod "." "f" ".*sh" #o755)
                (find-and-chmod "./Installer/xdg-utils" "f" "xdg-.*" #o755)
                (chmod "./renoise" #o755)
                (find-and-chmod "./Resources" "f"
                                "AudioPluginServer_.*" #o755)

                (copy-recursively "./Resources" out)
                (install-file "./renoise" out)

                (let ((renoise-binary (string-append out "/renoise")))
                  (mkdir-p bin)
                  (symlink renoise-binary (string-append bin "/renoise"))
                  (symlink renoise-binary
                           (string-append bin "/renoise-" version)))

                (let ((desktop-file "./Installer/renoise.desktop"))
                  (substitute* desktop-file
                    (("(Exec=).*( .*)$" all exec ending)
                     (string-append exec bin "/renoise" ending)))
                  (install-file desktop-file
                                (string-append share "/applications")))

                (for-each (lambda (res)
                            (let ((icons-dir
                                   (string-append share "/icons/hicolor/"
                                                  res "x" res "/apps")))
                              (mkdir-p icons-dir)
                              (copy-file
                               (string-append "./Installer/renoise-" res ".png")
                               (string-append icons-dir "/renoise.png"))))
                          '("48" "64" "128"))

                (install-file "./Installer/renoise.xml"
                              (string-append share "/mime/packages"))
                (install-file "./Installer/renoise.1.gz"
                              (string-append share "/man/man1"))
                (install-file "./Installer/renoise-pattern-effects.5.gz"
                              (string-append share "/man/man5"))

                ;; Prefix the user's home-profile lib dir so renoise and
                ;; its AudioPluginServer child resolve libstdc++/libgcc
                ;; from the same place as the rpath'd VST3 plugins
                ;; (see ~/bin/patch-vsts). Without this, the package's
                ;; build-time gcc-lib mismatches the home profile's
                ;; gcc-lib and plugins crash on GUI init.
                ;;
                ;; pipewire-0.3/jack must come BEFORE the main lib dir
                ;; — the home profile has both a real (legacy) libjack
                ;; via the jack-0.125.0 package and the pipewire-jack
                ;; shim, and whichever appears first in LD_LIBRARY_PATH
                ;; wins. Without this, Renoise's JACK driver opens the
                ;; real jack1 (which isn't running) and you have to
                ;; launch via `pw-jack renoise` to get pipewire.
                (wrap-program (string-append out "/bin/renoise")
                  `("LD_LIBRARY_PATH" ":" prefix
                    ("$HOME/.guix-home/profile/lib/pipewire-0.3/jack"
                     "$HOME/.guix-home/profile/lib")))))))))
    (inputs (list alsa-lib
                  `(,gcc "lib")
                  libx11
                  libxext
                  mpg123))
    (supported-systems '("x86_64-linux"))
    (synopsis "Modern tracker-based DAW")
    (description "Renoise is a digital audio workstation with a tracker-based
sequencer.  This package wraps the user's locally-downloaded registered
release tarball.")
    (home-page "https://www.renoise.com/")
    (license (license:nonfree
              (string-append "file:///share/doc/renoise-" "3.5.4"
                             "/License.txt")))))

renoise
