(define-module (noonker home emacs)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu packages)
  #:use-module (gnu services)
  #:use-module (guix gexp)
  #:export (emacs-daemon-service
            emacs-init-file))

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

;; The init file, tangled from ORG-FILE at build time.  Its blocks say
;; `:tangle ~/.emacs', so HOME decides where the result lands.
(define (emacs-init-file org-file)
  (computed-file
   "dot-emacs"
   #~(let ((home (string-append (getcwd) "/home")))
       (mkdir home)
       (setenv "HOME" home)
       (unless (zero? (system* #$(file-append
                                  (specification->package "emacs-pgtk")
                                  "/bin/emacs")
                               "--batch" "-l" "org" "--eval"
                               (format #f "(org-babel-tangle-file ~s)"
                                       #$org-file)))
         (error "tangling failed"))
       (copy-file (string-append home "/.emacs") #$output))))
