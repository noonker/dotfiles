(define-module (noonker home hydroxide)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu packages)
  #:use-module (gnu services)
  #:use-module (guix gexp)
  #:export (hydroxide-daemon-service))

(define hydroxide-shepherd-service
  (shepherd-service
   (provision '(hydroxide))
   (documentation "Run Hydroxide as a daemon.")
   (start #~(make-forkexec-constructor
             (list #$(file-append
                      (specification->package "hydroxide")
                      "/bin/hydroxide")
                   "serve")
             #:log-file (string-append
                         (getenv "HOME")
                         "/.local/var/log/hydroxide.log")))
   (stop #~(make-kill-destructor))
   (respawn? #f)))

(define hydroxide-daemon-service
  (simple-service 'hydroxide-daemon
                  home-shepherd-service-type
                  (list hydroxide-shepherd-service)))
