(define-module (noonker home emacs)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu packages)
  #:use-module (gnu services)
  #:use-module (guix gexp)
  #:export (emacs-daemon-service))

(define emacs-shepherd-service
  (shepherd-service
   (provision '(emacs))
   (documentation "Run Emacs as a daemon.")
   (start #~(make-forkexec-constructor
             (list #$(file-append
                      (specification->package "emacs-pgtk")
                      "/bin/emacs")
                   "--fg-daemon")
             #:log-file (string-append
                         (getenv "HOME")
                         "/.local/var/log/emacs.log")))
   (stop #~(make-kill-destructor))
   (respawn? #t)))

(define emacs-daemon-service
  (simple-service 'emacs-daemon
                  home-shepherd-service-type
                  (list emacs-shepherd-service)))
