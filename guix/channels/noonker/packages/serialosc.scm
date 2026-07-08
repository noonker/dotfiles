(define-module (noonker packages serialosc)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages)
  #:use-module (gnu packages audio)        ;liblo
  #:use-module (gnu packages avahi)        ;avahi (libdns_sd)
  #:use-module (gnu packages libevent)     ;libuv
  #:use-module (gnu packages linux)        ;eudev
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages pkg-config)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix build-system waf))

(define-public libmonome
  (package
    (name "libmonome")
    (version "1.4.9")
    (source
      (origin
        (method url-fetch)
        (uri "https://github.com/monome/libmonome/archive/refs/tags/v1.4.9.tar.gz")
        (sha256 (base32 "1f08iryjl4rczxxwpni84hj0qwv11zi9b1ia7lkraj4ciwqm2nql"))))
    (build-system waf-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (add-before 'configure 'set-ldflags
            (lambda _
              (setenv "LDFLAGS"
                      (string-append "-Wl,-rpath=" #$output "/lib")))))))
    (native-inputs (list pkg-config))
    (inputs (list eudev liblo ncurses))
    (home-page "https://github.com/monome/libmonome")
    (synopsis "Library for easy interaction with monome devices")
    (description "libmonome is a library for easy interaction with monome devices.")
    (license license:isc)))

(define-public serialosc
  (package
    (name "serialosc")
    (version "1.4.7")
    (source (origin
             (method git-fetch)
             (uri (git-reference
                   (url "https://github.com/monome/serialosc.git")
                   (commit "94d457f80fe3721d21df5190c99bd522c711185a")
                   (recursive? #t)))
             (file-name (git-file-name name version))
             (sha256
              (base32
               "0hfr30vrqvmj68h5h7c5fs276k2ik6yzn8v2q3ajn96a2n2p02ff"))))
    (build-system waf-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (add-before 'configure 'set-build-flags
            (lambda* (#:key inputs #:allow-other-keys)
              (let ((avahi (assoc-ref inputs "avahi")))
                (setenv "CFLAGS"
                        (string-append "-I" avahi
                                       "/include/avahi-compat-libdns_sd"))
                (setenv "LDFLAGS"
                        (string-append "-Wl,-rpath=" #$output "/lib")))))
          (add-after 'unpack 'patch-dlopen-libdns_sd
            (lambda* (#:key inputs #:allow-other-keys)
              (substitute* "src/serialosc-device/zeroconf/not_darwin.c"
                (("dlopen\\(\"libdns_sd\\.so\"")
                 (string-append "dlopen(\""
                                (assoc-ref inputs "avahi")
                                "/lib/libdns_sd.so\"")))))
          (add-after 'unpack 'skip-git-commit-lookup
            (lambda _
              (substitute* "wscript"
                (("subprocess\\.check_output\\(")
                 "(lambda *a, **k: b'')(")))))))
    (native-inputs (list pkg-config))
    (inputs (list liblo libuv libmonome eudev avahi))
    (home-page "https://github.com/monome/serialosc")
    (synopsis "OSC server for monome serial devices")
    (description "serialosc is a daemon that translates between monome serial
devices and the Open Sound Control (OSC) protocol, allowing applications to
communicate with grid and arc controllers over the network.")
    (license license:isc)))

serialosc
