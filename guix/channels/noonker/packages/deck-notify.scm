(define-module (noonker packages deck-notify)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (guix build-system copy)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-xyz))

(define-public deck-notify
  (package
    (name "deck-notify")
    (version "0.2.0")
    (source (local-file "deck-notify.py"))
    (build-system copy-build-system)
    (arguments
     (list
      #:install-plan #~'(("deck-notify.py" "bin/deck-notify"))
      #:phases
      #~(modify-phases %standard-phases
          (replace 'unpack
            (lambda* (#:key source #:allow-other-keys)
              (copy-file source "deck-notify.py")))
          (add-after 'install 'wrap
            (lambda* (#:key inputs #:allow-other-keys)
              (let ((bin (string-append #$output "/bin/deck-notify"))
                    (dirs (map cdr inputs)))
                (chmod bin #o755)
                (wrap-program bin
                  `("GI_TYPELIB_PATH" ":" prefix
                    ,(search-path-as-list '("lib/girepository-1.0") dirs))
                  `("GUIX_PYTHONPATH" ":" prefix
                    ,(search-path-as-list
                      '(#$(string-append
                           "lib/python"
                           (version-major+minor (package-version python))
                           "/site-packages"))
                      dirs))
                  ;; So that application icons shipped as SVG can be loaded.
                  `("GDK_PIXBUF_MODULE_FILE" =
                    (,(search-input-file
                       inputs
                       "lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"))))))))))
    (inputs
     (list bash-minimal
           gobject-introspection
           gtk+
           gtk-layer-shell
           librsvg
           python
           python-pycairo
           python-pygobject))
    (home-page "https://github.com/noonker/dotfiles")
    (synopsis "Notification daemon that draws notifications as a deck of cards")
    (description
     "A freedesktop notification daemon for Wayland compositors.  The newest
notification is the top card of a deck: its rank is the number of cards in the
deck, its suit is the application's icon, and its face shows the text.")
    (license license:gpl3+)))

deck-notify
