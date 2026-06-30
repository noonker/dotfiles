(define-module (noonker home pw-autoconnect)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu services)
  #:use-module (guix gexp)
  #:export (pw-autoconnect-daemon-service
            pw-autoconnect-renoise-daemon-service
            pw-autoconnect-m8-daemon-service))

(define (pw-autoconnect-service name script-basename doc)
  (shepherd-service
   (provision (list name))
   (documentation doc)
   (start #~(make-forkexec-constructor
             (list "/bin/sh"
                   (string-append (getenv "HOME")
                                  "/bin/" #$script-basename))
             #:log-file (string-append
                         (getenv "HOME")
                         "/.local/var/log/" #$script-basename ".log")))
   (stop #~(make-kill-destructor))
   (respawn? #t)))

(define pw-autoconnect-daemon-service
  (simple-service 'pw-autoconnect-daemon
                  home-shepherd-service-type
                  (list (pw-autoconnect-service
                         'pw-autoconnect
                         "pw-autoconnect-deluge-carla"
                         "Auto-link Deluge MIDI 1 <-> Carla and Carla audio-out to the default sink."))))

(define pw-autoconnect-renoise-daemon-service
  (simple-service 'pw-autoconnect-renoise-daemon
                  home-shepherd-service-type
                  (list (pw-autoconnect-service
                         'pw-autoconnect-renoise
                         "pw-autoconnect-renoise-carla"
                         "Auto-link Renoise MIDI Out Sync -> Carla events-in."))))

(define pw-autoconnect-m8-daemon-service
  (simple-service 'pw-autoconnect-m8-daemon
                  home-shepherd-service-type
                  (list (pw-autoconnect-service
                         'pw-autoconnect-m8
                         "pw-autoconnect-m8-carla"
                         "Auto-link M8 MIDI 1 -> Carla events-in and Carla audio-out -> M8 analog-stereo."))))
