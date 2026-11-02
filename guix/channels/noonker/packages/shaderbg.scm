(define-module (noonker packages shaderbg)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages window-management)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:export (shaderbg-baked))

;; shaderbg with native resolution, the real clock, and a baked layer; see the patch.
;; It still installs bin/shaderbg, so don't put this in a profile with plain shaderbg.
(define shaderbg-baked
  (package/inherit shaderbg
    (name "shaderbg-baked")
    (source
     (origin
       (inherit (package-source shaderbg))
       (patches (list (local-file "shaderbg-bake.patch")))))
    (native-inputs
     (modify-inputs (package-native-inputs shaderbg)
       (append wayland-protocols)))))
