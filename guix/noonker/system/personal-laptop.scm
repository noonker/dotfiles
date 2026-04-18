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
  #:use-module (gnu packages cups)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages ssh)
  #:use-module (gnu packages wm)
  #:use-module (gnu services desktop)
  #:use-module (gnu system accounts)
  #:use-module (gnu system setuid)
  #:use-module (guix records)
  #:use-module (noonker services boltd)
  #:use-module (noonker services podman)
  #:use-module (noonker services audio)

  ;; Nongnu (shhh.....)
   #:use-module (nongnu packages linux)
   #:use-module (nongnu system linux-initrd)
)

(use-service-modules cups desktop networking ssh xorg avahi)

(define %bladerf-udev-rule
  (udev-rule
   "90-bladerf-xA4.rules"
   (string-append "SUBSYSTEM==\"usb\", ATTRS{idVendor}==\"2cf0\", ATTRS{idProduct}==\"5250\", MODE=\"0660\", GROUP=\"input\"")))

(define %capslock-hwdb-udev-rule
  (udev-hardware "99-capslock-remap.hwdb"
              (string-append
               "evdev:atkbd:dmi:*\n"
               " KEYBOARD_KEY_3a=leftctrl\n")))

(define %monome-udev-rule
  (udev-rule
   "50-monome.rules"
   (string-append "SUBSYSTEM==\"tty\", ATTRS{idVendor}==\"cafe\", MODE=\"0666\"")
   )
  )

(operating-system 
  (locale "en_US.utf8")
  (timezone "America/Chicago")
  (keyboard-layout (keyboard-layout "us" 
                                    #:options '("ctrl:nocaps")))
  (host-name "blep")
  (kernel linux)
  (kernel-arguments
   (append
    (list "quiet")
    %default-kernel-arguments))
  (initrd microcode-initrd)
  (firmware (list linux-firmware))
  (name-service-switch %mdns-host-lookup-nss)
  ;; The list of user accounts ('root' is implicit).
  (users (cons* (user-account
                  (name "person")
                  (comment "Person")
                  (group "users")
                  (home-directory "/home/person")
                  (supplementary-groups '("realtime" "wheel" "netdev" "audio" "input" "video" "dialout")))
		;; Norns-Desktop Account
		(user-account
		 (name "we")
		 (group "users")
		 (supplementary-groups '("realtime" "wheel" "audio" "video" "dialout")))
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
   (cons* (service cups-service-type
		   (cups-configuration
		    (web-interface? #t)
		    (extensions
		     (list cups-filters))))
	  (service subids-service-type
                   (subids-configuration
                    (add-root? #f)
                    (subuids (list (subid-range (name "person"))))
                    (subgids (list (subid-range (name "person"))))))
          (service boltd-service-type)
	  (service bluetooth-service-type)
	  (service block-facebook-hosts-service-type) 
	  (service nftables-service-type)
	  (service greetd-service-type
		   (greetd-configuration
		    (greeter-supplementary-groups '("video" "input"))
		    (terminals
		     (list
		      (greetd-terminal-configuration
                       (terminal-vt "7")
                       (terminal-switch #t)
                       (default-session-command
			 (greetd-agreety-session
			  (command
			   (greetd-user-session
			    (command (file-append sway "/bin/sway"))
			    (command-args '())
			    (xdg-session-type "wayland"))))))))))
	  (service screen-locker-service-type
                   (screen-locker-configuration
                   (name "swaylock")
                   (program (file-append swaylock "/bin/swaylock"))
                   (using-pam? #t)
                   (using-setuid? #f)))
	  (udev-rules-service 'bladerf %bladerf-udev-rule)
	  (udev-rules-service 'monome %monome-udev-rule)
	  (udev-hardware-service 'capslock %capslock-hwdb-udev-rule) 
	  audio-realtime-service
          podman-iptables
           ;; This is the default list of services we
           ;; are appending to.
	  (modify-services %desktop-services
		 (delete gdm-service-type))))
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
