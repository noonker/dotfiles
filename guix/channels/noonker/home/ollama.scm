(define-module (noonker home ollama)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu packages)
  #:use-module (gnu services)
  #:use-module (guix gexp)
  #:export (ollama-daemon-service))

(define ollama-shepherd-service
  (shepherd-service
   (provision '(ollama))
   (documentation "Run ollama as a daemon.")
   (start #~(make-forkexec-constructor
             (list #$(file-append
                      (specification->package "ollama-linux-amd64")
                      "/bin/ollama")
                   "serve")
             #:log-file (string-append
                         (getenv "HOME")
                         "/.local/var/log/ollama.log")))
   (stop #~(make-kill-destructor))
   (respawn? #t)))

(define ollama-daemon-service
  (simple-service 'ollama-daemon
                  home-shepherd-service-type
                  (list ollama-shepherd-service)))
