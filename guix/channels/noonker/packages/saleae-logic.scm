;; Packages the locally-downloaded Saleae Logic 2 AppImage.
;; The AppImage is unpacked at build time via `unsquashfs`, then the
;; Electron/Chromium binaries are patchelf'd for the Guix runtime.

(define-module (noonker packages saleae-logic)
  #:use-module (gnu packages compression)  ; squashfs-tools
  #:use-module (gnu packages cups)
  #:use-module (gnu packages gcc)          ; gcc:lib
  #:use-module (gnu packages gl)           ; mesa
  #:use-module (gnu packages glib)         ; glib, dbus
  #:use-module (gnu packages gtk)          ; gtk+, pango, cairo, at-spi2-core
  #:use-module (gnu packages linux)        ; alsa-lib, eudev
  #:use-module (gnu packages nss)          ; nss, nspr
  #:use-module (gnu packages xdisorg)      ; libxkbcommon
  #:use-module (gnu packages xml)          ; expat
  #:use-module (gnu packages xorg)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module ((nonguix licenses) #:prefix license:)
  #:use-module (nonguix build-system binary)
  #:export (saleae-logic))

(define %saleae-logic-appimage
  (string-append (getenv "HOME")
                 "/Downloads/Logic-2.4.46-linux-x64.AppImage"))

(define-public saleae-logic
  (package
    (name "saleae-logic")
    (version "2.4.46")
    (source (local-file %saleae-logic-appimage))
    (build-system binary-build-system)
    (arguments
     (list
      #:strip-binaries? #f
      #:validate-runpath? #f
      ;; We handle patchelf manually so we can inject `$ORIGIN' into
      ;; the RPATH — Electron/Chromium sub-libraries (libffmpeg.so,
      ;; libEGL.so, libAnalyzer.so, …) sit next to Logic.bin and must
      ;; resolve without leaking a wrapper's LD_LIBRARY_PATH into
      ;; child processes.
      #:patchelf-plan #~'()
      #:phases
      #~(modify-phases %standard-phases
          (replace 'unpack
            (lambda* (#:key source #:allow-other-keys)
              (use-modules (rnrs bytevectors)
                           (rnrs io ports))
              ;; AppImage Type-2 is an ELF wrapper followed by a
              ;; squashfs image.  The squashfs begins at the end of
              ;; the ELF section-header table.
              (define (appimage-squashfs-offset file)
                (let* ((port (open-file file "rb"))
                       (hdr  (get-bytevector-n port 64)))
                  (close-port port)
                  (+ (bytevector-u64-ref hdr #x28 'little)
                     (* (bytevector-u16-ref hdr #x3a 'little)
                        (bytevector-u16-ref hdr #x3c 'little)))))
              (invoke "unsquashfs"
                      "-o" (number->string (appimage-squashfs-offset source))
                      "-d" "squashfs-root"
                      "-f"
                      source)
              (chdir "squashfs-root")))
          (delete 'patchelf)
          (add-before 'install 'patchelf-interpreter
            ;; Only fix the ELF interpreter on the two entry-point
            ;; binaries.  Every other .so and .node file keeps its
            ;; original RPATH so that numpy's `$ORIGIN/../../numpy.libs'
            ;; auditwheel pattern (and analyzer plugins' `$ORIGIN/..'
            ;; lookup of libAnalyzer.so) still resolves.  Guix libraries
            ;; come from LD_LIBRARY_PATH set by wrap-program below.
            (lambda* (#:key inputs #:allow-other-keys)
              (let ((ld-so (car (find-files (assoc-ref inputs "libc")
                                            "^ld-linux.*\\.so"))))
                (invoke "patchelf" "--set-interpreter" ld-so
                        "usr/lib/logic/Logic.bin")
                (invoke "patchelf" "--set-interpreter" ld-so
                        "usr/lib/logic/chrome_crashpad_handler"))))
          (replace 'install
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((out   (assoc-ref outputs "out"))
                     (share (string-append out "/share"))
                     (bin   (string-append out "/bin"))
                     (app   (string-append out "/opt/saleae-logic")))
                (chmod "usr/lib/logic/Logic" #o755)
                (chmod "usr/lib/logic/Logic.bin" #o755)
                (chmod "usr/lib/logic/chrome_crashpad_handler" #o755)
                (mkdir-p app)
                (copy-recursively "usr/lib/logic" app)
                (mkdir-p bin)
                (symlink (string-append app "/Logic")
                         (string-append bin "/saleae-logic"))
                ;; Inject Guix library paths via LD_LIBRARY_PATH rather
                ;; than rewriting each .so's RPATH: the app's bundled
                ;; Python native modules ship with auditwheel-style
                ;; `$ORIGIN/../../numpy.libs' entries that must survive
                ;; to find libscipy_openblas etc. LD_LIBRARY_PATH takes
                ;; precedence over RUNPATH for the missing system libs
                ;; (libstdc++, libudev, …) without clobbering $ORIGIN.
                ;;
                ;; FONTCONFIG_PATH also has to be set — without it
                ;; Chromium fails to load fonts and renders a black
                ;; window.
                (define (input-lib name . rest)
                  (string-append (assoc-ref inputs name)
                                 (if (null? rest) "/lib" (car rest))))
                (let ((guix-libs
                       (string-join
                        (cons (input-lib "nss" "/lib/nss")
                              (map input-lib
                                   '("libc" "gcc" "glib" "nspr"
                                     "at-spi2-core" "cups" "dbus"
                                     "cairo" "gtk+" "pango" "libx11"
                                     "libxcomposite" "libxdamage"
                                     "libxext" "libxfixes" "libxrandr"
                                     "mesa" "expat" "libxcb"
                                     "libxkbcommon" "eudev"
                                     "alsa-lib")))
                        ":")))
                  (wrap-program (string-append app "/Logic.bin")
                    `("FONTCONFIG_PATH" ":" prefix
                      ("$HOME/.guix-home/profile/etc/fonts"))
                    `("LD_LIBRARY_PATH" ":" prefix (,guix-libs))))
                (let ((desktop (string-append share
                                              "/applications/saleae-logic.desktop")))
                  (mkdir-p (dirname desktop))
                  (call-with-output-file desktop
                    (lambda (p)
                      (format p "\
[Desktop Entry]
Version=1.0
Type=Application
Name=Saleae Logic
GenericName=Logic Analyzer
Comment=Saleae Logic analyzer software
Exec=~a/saleae-logic %U
Icon=saleae-logic
Terminal=false
Categories=Development;Electronics;
~%" bin))))
                (let ((icons (string-append share
                                            "/icons/hicolor/1024x1024/apps")))
                  (mkdir-p icons)
                  (copy-file (string-append app
                                            "/resources/linux-x64/LogicIcon.png")
                             (string-append icons "/saleae-logic.png")))
                ;; Ship udev rules under lib/udev/rules.d/ so a system
                ;; config can pick them up with
                ;;   (udev-rules-service 'saleae-logic saleae-logic).
                (let ((udev-dir (string-append out "/lib/udev/rules.d")))
                  (mkdir-p udev-dir)
                  (copy-file (string-append app
                                            "/resources/udev/99-SaleaeLogic.rules")
                             (string-append udev-dir
                                            "/99-SaleaeLogic.rules"))
                  (copy-file (string-append app
                                            "/resources/udev/99-SaleaeLogic-v1.rules")
                             (string-append udev-dir
                                            "/99-SaleaeLogic-v1.rules")))))))))
    (inputs
     (list `(,gcc "lib")
           alsa-lib
           at-spi2-core
           cairo
           cups
           dbus
           eudev
           expat
           glib
           gtk+
           libx11
           libxcb
           libxcomposite
           libxdamage
           libxext
           libxfixes
           libxkbcommon
           libxrandr
           mesa
           nspr
           nss
           pango))
    (native-inputs (list squashfs-tools))
    (supported-systems '("x86_64-linux"))
    (synopsis "Saleae Logic 2 analyzer application")
    (description "Saleae Logic 2 is the host application for Saleae USB
logic analyzers.  This package unpacks the vendor-supplied AppImage and
patches its Electron/Chromium binaries for the Guix runtime.

Ships udev rules under @file{lib/udev/rules.d/} for rootless USB access
to Saleae hardware — wire them in with
@code{(udev-rules-service 'saleae-logic saleae-logic)}.")
    (home-page "https://www.saleae.com/")
    (license (license:nonfree
              "https://downloads.saleae.com/logic2/eula.html"))))

saleae-logic
