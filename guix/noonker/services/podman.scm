(define-module (noonker services podman)
  #:use-module (guix)
  #:use-module (gnu)
  #:use-module (gnu services)
  #:use-module (gnu services networking)
  #:use-module (guix gexp)
  #:export (podman-iptables))

(define podman-iptables (service iptables-service-type
				 (iptables-configuration)))
