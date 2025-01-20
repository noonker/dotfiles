(define-module (noonker services audio)
  #:use-module (gnu system accounts)
  #:use-module (gnu services)
  #:use-module (gnu services base)
  #:use-module (gnu system pam)
  #:export (audio-realtime-service
            audio-realtime-group))

(define audio-realtime-group
  (user-group (system? #t) (name "realtime"))
  )

(define audio-realtime-service
  (service pam-limits-service-type
           (list
            (pam-limits-entry "@realtime" 'both 'rtprio 99)
            (pam-limits-entry "@realtime" 'both 'nice -19)
            (pam-limits-entry "@realtime" 'both 'memlock 'unlimited))))
