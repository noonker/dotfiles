(define-module (noonker packages wine)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix utils)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system trivial)
  #:use-module (gnu packages)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages audio)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages cups)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages flex)
  #:use-module (gnu packages image)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages ghostscript)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gstreamer)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages kerberos)
  #:use-module (gnu packages libusb)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages openldap)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages mp3)
  #:use-module (gnu packages photo)
  #:use-module (gnu packages samba)
  #:use-module (gnu packages scanner)
  #:use-module (gnu packages sdl)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages video)
  #:use-module (gnu packages vulkan)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages xorg)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)
  #:export (wine-9.21-staging
            wine64-9.21-staging))

(define wine-9.21-minimal
  (package
    (name "wine-minimal")
    (version "9.21")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://dl.winehq.org/wine/source/9.x/"
                           "wine-" version ".tar.xz"))
       (sha256
        (base32 "1zrgra4ajxaic1ga4yfvv4lxix76sigysdhf21bs8blvzmzv8hj4"))))
    (build-system gnu-build-system)
    (native-inputs (list bison flex))
    (inputs `())
    (arguments
     (list
      #:system (match (%current-system)
                 ((or "armhf-linux" "aarch64-linux") "armhf-linux")
                 (_ "i686-linux"))
      #:tests? #f
      #:make-flags
      #~(list "SHELL=bash"
              (string-append "libdir=" #$output "/lib/wine32"))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'patch-SHELL
            (lambda _
              (substitute* "configure"
                (("/bin/sh")
                 (which "bash")))))
          (add-after 'configure 'patch-dlopen-paths
            (lambda _
              (let* ((library-path (search-path-as-string->list
                                    (getenv "LIBRARY_PATH")))
                     (find-so (lambda (soname)
                                (search-path library-path soname))))
                (substitute* "include/config.h"
                  (("(#define SONAME_.* )\"(.*)\"" _ defso soname)
                   (format #f "~a\"~a\"" defso (find-so soname)))))))
          (add-after 'patch-generated-file-shebangs 'patch-makedep
            (lambda* (#:key outputs #:allow-other-keys)
              (substitute* "tools/makedep.c"
                (("output_filenames\\( unix_libs \\);" all)
                 (string-append all
                  "output ( \" -Wl,-rpath=%s \", arch_install_dirs[arch] );")))))
          (add-before 'build 'set-widl-time-override
            (lambda _
              (setenv "WIDL_TIME_OVERRIDE" "315532800"))))
      #:configure-flags
      #~(list "--without-freetype"
              "--without-x")))
    (home-page "https://www.winehq.org/")
    (synopsis "Implementation of the Windows API (32-bit only)")
    (description
     "Wine (originally an acronym for \"Wine Is Not an Emulator\") is a
compatibility layer capable of running Windows applications.  Instead of
simulating internal Windows logic like a virtual machine or emulator, Wine
translates Windows API calls into POSIX calls on-the-fly, eliminating the
performance and memory penalties of other methods and allowing you to cleanly
integrate Windows applications into your desktop.")
    (supported-systems '("i686-linux" "x86_64-linux" "armhf-linux"))
    (license license:lgpl2.1+)))

(define wine-9.21
  (package
    (inherit wine-9.21-minimal)
    (name "wine")
    (native-inputs
     (modify-inputs (package-native-inputs wine-9.21-minimal)
       (prepend gettext-minimal perl pkg-config)))
    (inputs
     (list alsa-lib
           bash-minimal
           cups
           dbus
           eudev
           fontconfig
           freetype
           gnutls
           gst-plugins-base
           libgphoto2
           openldap
           samba
           sane-backends
           libpcap
           libusb
           libice
           libx11
           libxi
           libxext
           libxcursor
           libxkbcommon
           libxrender
           libxrandr
           libxinerama
           libxxf86vm
           libxcomposite
           mesa
           mit-krb5
           openal
           pulseaudio
           sdl2
           unixodbc
           v4l-utils
           vkd3d
           vulkan-loader
           wayland
           wayland-protocols))
    (arguments
     (substitute-keyword-arguments (package-arguments wine-9.21-minimal)
       ((#:phases phases)
        #~(modify-phases #$phases
           #$@(match (%current-system)
                ((or "i686-linux" "x86_64-linux")
                 `((add-after 'install 'wrap-executable
                     (lambda* (#:key inputs outputs #:allow-other-keys)
                       (let* ((out (assoc-ref outputs "out"))
                              (icd (string-append out "/share/vulkan/icd.d")))
                         (mkdir-p icd)
                         (copy-file (search-input-file
                                     inputs
                                     "/share/vulkan/icd.d/radeon_icd.i686.json")
                                    (string-append icd "/radeon_icd.i686.json"))
                         (copy-file (search-input-file
                                     inputs
                                     "/share/vulkan/icd.d/intel_icd.i686.json")
                                    (string-append icd "/intel_icd.i686.json"))
                         (wrap-program (string-append out "/bin/wine-preloader")
                           `("VK_ICD_FILENAMES" ":" =
                             (,(string-append icd
                                              "/radeon_icd.i686.json" ":"
                                              icd "/intel_icd.i686.json")))))))))
                (_
                 `()))))
       ((#:configure-flags _ '()) #~'())))))

(define wine64-9.21
  (package
    (inherit wine-9.21)
    (name "wine64")
    (inputs (modify-inputs (package-inputs wine-9.21)
              (prepend wine-9.21)))
    (arguments
     (substitute-keyword-arguments
         (strip-keyword-arguments '(#:system) (package-arguments wine-9.21))
       ((#:make-flags _)
        #~(list "SHELL=bash"
                (string-append "libdir=" #$output "/lib/wine64")))
       ((#:phases phases)
        #~(modify-phases #$phases
            (add-after 'install 'copy-wine32-binaries
              (lambda* (#:key inputs outputs #:allow-other-keys)
                (let ((out (assoc-ref %outputs "out")))
                  (copy-file (search-input-file inputs "/bin/wine")
                             (string-append out "/bin/wine"))
                  (copy-file (search-input-file inputs "/bin/.wine-preloader-real")
                             (string-append out "/bin/wine-preloader")))))
            (add-after 'install 'copy-wine32-libraries
              (lambda* (#:key inputs outputs #:allow-other-keys)
                (let* ((out (assoc-ref %outputs "out")))
                  (copy-recursively (search-input-directory inputs "/lib/wine32")
                                    (string-append out "/lib/wine32")))))
            #$@(match (%current-system)
                 ((or "x86_64-linux")
                  `((delete 'wrap-executable)
                    (add-after 'copy-wine32-binaries 'wrap-executable
                      (lambda* (#:key inputs outputs #:allow-other-keys)
                        (let* ((out (assoc-ref outputs "out"))
                               (icd-files (map
                                           (lambda (basename)
                                             (search-input-file
                                              inputs
                                              (string-append "/share/vulkan/icd.d/"
                                                             basename)))
                                           '("radeon_icd.x86_64.json"
                                             "intel_icd.x86_64.json"
                                             "radeon_icd.i686.json"
                                             "intel_icd.i686.json"))))
                          (wrap-program (string-append out "/bin/wine-preloader")
                            `("VK_ICD_FILENAMES" ":" = ,icd-files))
                          (wrap-program (string-append out "/bin/wine64-preloader")
                            `("VK_ICD_FILENAMES" ":" = ,icd-files)))))))
                 (_
                  `()))
            (add-after 'compress-documentation 'copy-wine32-manpage
              (lambda* (#:key inputs outputs #:allow-other-keys)
                (let* ((out (assoc-ref %outputs "out")))
                  (copy-file (search-input-file inputs "/share/man/man1/wine.1.zst")
                             (string-append out "/share/man/man1/wine.1.zst")))))))
       ((#:configure-flags configure-flags '())
        #~(cons "--enable-win64" #$configure-flags))))
    (synopsis "Implementation of the Windows API (WoW64 version)")
    (supported-systems '("x86_64-linux" "aarch64-linux"))))

(define wine-9.21-staging-patchset-data
  (package
    (name "wine-staging-patchset-data")
    (version "9.21")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/wine-staging/wine-staging")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0xaz8b3ir45jmzwkcyglfz89f5la5r4y08yj2fq5fcrg2p6nqcql"))))
    (build-system trivial-build-system)
    (native-inputs
     (list coreutils))
    (arguments
     `(#:modules ((guix build utils))
       #:builder
       (begin
         (use-modules (guix build utils))
         (let* ((build-directory ,(string-append name "-" version))
                (source (assoc-ref %build-inputs "source"))
                (coreutils (assoc-ref %build-inputs "coreutils"))
                (out (assoc-ref %outputs "out"))
                (wine-staging (string-append out "/share/wine-staging")))
           (copy-recursively source build-directory)
           (with-directory-excursion build-directory
             (substitute* '("patches/gitapply.sh" "staging/patchinstall.py")
               (("/usr/bin/env")
                (string-append coreutils "/bin/env"))))
           (copy-recursively build-directory wine-staging)
           #t))))
    (home-page "https://github.com/wine-staging")
    (synopsis "Patchset for Wine")
    (description
     "wine-staging-patchset-data contains the patchset to build Wine-Staging.")
    (license license:lgpl2.1+)))

(define-public wine-9.21-staging
  (package
    (inherit wine-9.21)
    (name "wine-staging")
    (version (package-version wine-9.21-staging-patchset-data))
    (source (package-source wine-9.21-minimal))
    (inputs (modify-inputs (package-inputs wine-9.21)
              (prepend autoconf
                       ffmpeg
                       gtk+
                       libva
                       mesa
                       python
                       util-linux
                       wine-9.21-staging-patchset-data)))
    (native-inputs
     (modify-inputs (package-native-inputs wine-9.21)
       (prepend python-3)))
    (arguments
     (substitute-keyword-arguments (package-arguments wine-9.21)
       ((#:phases phases)
        #~(modify-phases #$phases
            (delete 'patch-SHELL)
            (add-before 'configure 'apply-wine-staging-patches
              (lambda* (#:key inputs #:allow-other-keys)
                (invoke (search-input-file
                         inputs
                         "/share/wine-staging/staging/patchinstall.py")
                        "DESTDIR=."
                        ;; Broken upstream, does not apply.
                        "-W" "server-Stored_ACLs"
                        "--all")))
            (add-after 'apply-wine-staging-patches 'patch-SHELL
              (assoc-ref #$phases 'patch-SHELL))))))
    (synopsis "Implementation of the Windows API (staging branch, 32-bit only)")
    (description "Wine-Staging is the testing area of Wine.  It
contains bug fixes and features, which have not been integrated into
the development branch yet.  The idea of Wine-Staging is to provide
experimental features faster to end users and to give developers the
possibility to discuss and improve their patches before they are
integrated into the main branch.")
    (home-page "https://github.com/wine-staging")
    (license
     (list license:lgpl2.1+ license:silofl1.1 license:gpl3+ license:asl2.0))))

(define-public wine64-9.21-staging
  (package
    (inherit wine-9.21-staging)
    (name "wine64-staging")
    (inputs (modify-inputs (package-inputs wine-9.21-staging)
              (prepend wine-9.21-staging)))
    (arguments
     (substitute-keyword-arguments (package-arguments wine64-9.21)
       ((#:phases phases)
        #~(modify-phases #$phases
            (delete 'patch-SHELL)
            (add-before 'configure 'apply-wine-staging-patches
              (lambda* (#:key inputs #:allow-other-keys)
                (invoke (search-input-file
                         inputs
                         "/share/wine-staging/staging/patchinstall.py")
                        "DESTDIR=."
                        ;; Note: Keep in sync with wine-9.21-staging.
                        "-W" "server-Stored_ACLs"
                        "--all")))
            (add-after 'apply-wine-staging-patches 'patch-SHELL
              (assoc-ref #$phases 'patch-SHELL))))))
    (synopsis "Implementation of the Windows API (staging branch, WoW64 version)")
    (supported-systems '("x86_64-linux" "aarch64-linux"))))
