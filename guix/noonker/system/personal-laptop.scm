;; This is an operating system configuration generated
;; by the graphical installer.
;;
;; Once installation is complete, you can learn and modify
;; this file to tweak the system configuration, and pass it
;; to the 'guix system reconfigure' command to effect your
;; changes.

(define-module (noonker system personal-laptop)
  #:use-module (gnu)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages radio)
  #:use-module (gnu packages ssh)
  #:use-module (guix records)
  #:use-module (noonker services boltd)
  #:use-module (noonker services podman)
  #:use-module (noonker services audio)

  ;; Nongnu (shhh.....)
   #:use-module (nongnu packages linux)
   #:use-module (nongnu system linux-initrd)
)

(use-service-modules cups desktop networking ssh xorg)

(define %bladerf-udev-rule
  (udev-rule
   "90-bladerf-xA4.rules"
   (string-append "SUBSYSTEM==\"usb\", ATTRS{idVendor}==\"2cf0\", ATTRS{idProduct}==\"5250\", MODE=\"0660\", GROUP=\"input\"")))

(operating-system
  (locale "en_US.utf8")
  (timezone "America/Chicago")
  (keyboard-layout (keyboard-layout "us"))
  (host-name "blep")
  (kernel linux)
;;  (kernel-arguments
;;   (append
;;    (list "nomodeset")
;;    %default-kernel-arguments))
  (initrd microcode-initrd)
  (firmware (list linux-firmware))
  
  ;; The list of user accounts ('root' is implicit).
  (users (cons* (user-account
                  (name "person")
                  (comment "Person")
                  (group "users")
                  (home-directory "/home/person")
                  (supplementary-groups '("realtime" "wheel" "netdev" "audio" "input" "video")))
                %base-user-accounts))

  ;; Add the 'realtime' group
   (groups (cons audio-realtime-group 
                 %base-groups))

  ;; Packages installed system-wide.  Users can also install packages
  ;; under their own account: use 'guix search KEYWORD' to search
  ;; for packages and 'guix install PACKAGE' to install a package.
   (packages (append (list (specification->package "nss-certs"))
		     (list bolt openssh bladerf cups
			   system-config-printer)
		     %base-packages))

  ;; Below is the list of system services.  To search for available
  ;; services, run 'guix system search KEYWORD' in a terminal.
  (services
   (cons* (service gnome-desktop-service-type)
	  (service cups-service-type
		   (cups-configuration
		    (web-interface? #t)
		    (extensions
		     (list cups-filters))))
          (service boltd-service-type)
	  (service bluetooth-service-type)
	  (service nftables-service-type)
          (udev-rules-service 'bladerf %bladerf-udev-rule)
          (set-xorg-configuration
           (xorg-configuration (keyboard-layout keyboard-layout)))
	  audio-realtime-service
	  podman-user-person-subuid
          podman-iptables
           ;; This is the default list of services we
           ;; are appending to.
          %desktop-services))
  (bootloader (bootloader-configuration
                (bootloader grub-efi-bootloader)
                (targets (list "/boot/efi"))
                (keyboard-layout keyboard-layout)))
  (mapped-devices (list (mapped-device
                          (source (uuid
                                   "a2d33754-ff7f-4854-a33c-60a740e63e72"))
                          (target "cryptroot")
                          (type luks-device-mapping))))

  ;; The list of file systems that get "mounted".  The unique
  ;; file system identifiers there ("UUIDs") can be obtained
  ;; by running 'blkid' in a terminal.
  (file-systems (cons* (file-system
                         (mount-point "/boot/efi")
                         (device (uuid "0F80-12F5"
                                       'fat32))
                         (type "vfat"))
                       (file-system
                         (mount-point "/")
                         (device "/dev/mapper/cryptroot")
                         (type "ext4")
                         (dependencies mapped-devices)) %base-file-systems)))
