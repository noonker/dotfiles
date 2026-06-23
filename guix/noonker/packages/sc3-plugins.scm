;; sc3-plugins: community SuperCollider UGen plugins (PV_*, MdaPiano,
;; Switchblade, SC3-Plugins ladspa list, etc.) required by various
;; SuperDirt synths (the "WARNING: Dirt could not load some synths ...
;; sc3plugins are necessary and missing" message disappears once these
;; are visible to scsynth).
;;
;; Guix's supercollider hardcodes its system extension directory at
;; compile time, so plugins shipped from a *different* store path are
;; never auto-discovered.  The plumbing lives in the home configuration:
;; this package just installs the plugins under
;; <out>/share/SuperCollider/Extensions/SC3plugins/ and the home config
;; symlinks that directory into ~/.local/share/SuperCollider/Extensions/,
;; which scsynth (and sclang) scan unconditionally.

(define-module (noonker packages sc3-plugins)
  #:use-module (gnu packages audio)         ;supercollider
  #:use-module (gnu packages cmake)
  #:use-module (gnu packages algebra)       ;fftw
  #:use-module (gnu packages pkg-config)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix build-system cmake)
  #:use-module (ice-9 ftw)
  #:export (sc3-plugins))

(define-public sc3-plugins
  (package
    (name "sc3-plugins")
    (version "3.14.0")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/supercollider/sc3-plugins.git")
                    (commit (string-append "Version-" version))
                    (recursive? #t)))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0rqppagzl1yssjkxkj4rgd0cnj9866yxplqc11icxppdn0cqxs39"))))
    (build-system cmake-build-system)
    (arguments
     (list
      #:tests? #f
      #:configure-flags
      #~(list (string-append "-DSC_PATH=" #$(package-source supercollider))
              "-DSUPERNOVA=ON"
              "-DCMAKE_BUILD_TYPE=Release")
      #:phases
      #~(modify-phases %standard-phases
          ;; sc3-plugins installs the UGen .so files under
          ;; <out>/lib/SuperCollider/plugins/SC3plugins/ and the .sc class
          ;; files under <out>/share/SuperCollider/Extensions/SC3plugins/.
          ;; Move the .so tree alongside the classes so a single symlink
          ;; under ~/.local/share/SuperCollider/Extensions/ exposes both
          ;; to sclang and scsynth.
          (add-after 'install 'colocate-ugens-with-classes
            (lambda _
              (use-modules (ice-9 ftw))
              (let* ((lib-plugins (string-append #$output
                                                 "/lib/SuperCollider/plugins"))
                     (ext-root   (string-append #$output
                                                 "/share/SuperCollider/Extensions/SC3plugins")))
                (when (file-exists? lib-plugins)
                  (mkdir-p ext-root)
                  (for-each
                   (lambda (entry)
                     (let ((src (string-append lib-plugins "/" entry))
                           (dst (string-append ext-root "/" entry)))
                       (when (file-exists? dst)
                         (delete-file-recursively dst))
                       (rename-file src dst)))
                   (scandir lib-plugins
                            (lambda (f) (not (member f '("." ".."))))))
                  (delete-file-recursively
                   (string-append #$output "/lib/SuperCollider")))))))))
    (native-inputs (list cmake pkg-config))
    (inputs (list fftw fftwf supercollider))
    (home-page "https://github.com/supercollider/sc3-plugins")
    (synopsis "Community UGen plugins for SuperCollider")
    (description
     "sc3-plugins is the community-maintained collection of UGen plugins
for SuperCollider (mda, MCLDUGens, PortedPlugins, BatUGens, AntiAliasingOscillators,
DistortionUGens, etc.).  Several SuperDirt synthdefs depend on it; without
sc3-plugins SuperCollider posts @samp{Dirt could not load some synths from
default-synths.scd, because sc3plugins are necessary and missing.} on
startup.  Built with the supernova backend enabled.")
    (license license:gpl2+)))

sc3-plugins
