(define-module (noonker home pw-autoconnect)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu services)
  #:use-module (guix gexp)
  #:export (pw-autoconnect-daemon-service))

(define pw-autoconnect-shepherd-service
  (shepherd-service
   (provision '(pw-autoconnect))
   (documentation
    "Auto-link Deluge MIDI 1 <-> Carla and Carla audio-out to the default sink.")
   (start #~(make-forkexec-constructor
             (list "/bin/sh"
                   (string-append (getenv "HOME")
                                  "/bin/pw-autoconnect-deluge-carla"))
             #:log-file (string-append
                         (getenv "HOME")
                         "/.local/var/log/pw-autoconnect.log")))
   (stop #~(make-kill-destructor))
   (respawn? #t)))

(define pw-autoconnect-daemon-service
  (simple-service 'pw-autoconnect-daemon
                  home-shepherd-service-type
                  (list pw-autoconnect-shepherd-service)))
