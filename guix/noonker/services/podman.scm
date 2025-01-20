(define-module (noonker services podman)
  #:use-module (guix)
  #:use-module (gnu)
  #:use-module (gnu services)
  #:use-module (gnu services base)
  #:use-module (gnu services networking)
  #:use-module (guix gexp)
  #:export (podman-user-person-subuid
	    podman-iptables
	    ))

(define podman-user-person-subuid
  (simple-service
   'podman-subuid-subgid
   ;; If subuid/subgid will be needed somewhere else, the service must be
   ;; created to handle it.
   etc-service-type
   `(("subuid"
      ,(plain-file
	"subuid"
	(string-append "person" ":100000:65536\n")))
     ("subgid"
      ,(plain-file
	"subgid"
	(string-append "person" ":100000:65536\n"))))))

(define podman-iptables (service iptables-service-type
					 (iptables-configuration)))
