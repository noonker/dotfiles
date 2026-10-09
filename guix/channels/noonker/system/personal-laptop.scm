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
  #:use-module (gnu packages window-management)
  #:use-module (gnu services desktop)
  #:use-module (gnu system accounts)
  #:use-module (gnu system setuid)
  #:use-module (guix gexp)
  #:use-module (guix records)
  #:use-module (noonker services boltd)
  #:use-module (noonker services podman)
  #:use-module (noonker services audio)
  #:use-module (noonker packages tailscale)
  #:use-module (noonker packages picotool)
  #:use-module (noonker packages saleae-logic)

  ;; Nongnu (shhh.....)
   #:use-module (nongnu packages linux)
   #:use-module (nongnu system linux-initrd)
)

(use-service-modules cups dbus desktop networking ssh xorg avahi)

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
   (string-append "SUBSYSTEM==\"tty\", ATTRS{idVendor}==\"cafe\", MODE=\"0666\", ENV{ID_MM_DEVICE_IGNORE}=\"1\"")
   )
  )

;; Raspberry Pi Debugprobe (CMSIS-DAP) — VID 2e8a:000c. Picotool's own
;; rules cover the RP2350 BOOTSEL VIDs but not the CMSIS-DAP interface,
;; so probe-rs shows the probe as "inaccessible" without this. Uses
;; TAG+="uaccess" so the active-seat user gets access via elogind.
(define %debugprobe-udev-rule
  (udev-rule
   "70-debugprobe.rules"
   (string-append "SUBSYSTEM==\"usb\", ATTRS{idVendor}==\"2e8a\", ATTRS{idProduct}==\"000c\", TAG+=\"uaccess\"")))

;; Flipper Zero — VID 0483:5740 is the CDC (normal) interface qFlipper
;; opens; 0483:df11 is the STM32 DFU interface used during firmware
;; flashing.
;;
;; MODE="0666" (rather than the TAG+="uaccess" pattern used for
;; debugprobe) because qFlipper is only usable inside a guix shell
;; --container FHS namespace, and that namespace remaps every uid
;; other than the invoking user to nobody(65534)/overflow(65534). ACLs
;; granted to `person` by elogind's uaccess don't survive that
;; remapping; a world-rw mode does. SUBSYSTEMS== (plural) walks up
;; the parent chain so the child /dev/ttyACM* CDC device also gets
;; the mode, not just the USB interface node under /dev/bus/usb.
(define %flipperzero-udev-rule
  (udev-rule
   "42-flipperzero.rules"
   (string-append
    "SUBSYSTEMS==\"usb\", ATTRS{idVendor}==\"0483\", ATTRS{idProduct}==\"5740\", MODE=\"0666\"\n"
    "SUBSYSTEMS==\"usb\", ATTRS{idVendor}==\"0483\", ATTRS{idProduct}==\"df11\", MODE=\"0666\"")))

;; Android adb — match the common phone-vendor USB VIDs so adb/fastboot can
;; talk to a plugged-in device without root. TAG+="uaccess" grants access to
;; the active-seat user via elogind, same approach as debugprobe. If the
;; phone's vendor isn't listed, grab its VID from `lsusb` and add a line.
(define %android-udev-rule
  (udev-rule
   "51-android.rules"
   (string-append
    "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"18d1\", MODE=\"0660\", TAG+=\"uaccess\"\n"  ;; Google / Pixel / Nexus
    "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"04e8\", MODE=\"0660\", TAG+=\"uaccess\"\n"  ;; Samsung
    "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"22b8\", MODE=\"0660\", TAG+=\"uaccess\"\n"  ;; Motorola
    "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"2a70\", MODE=\"0660\", TAG+=\"uaccess\"\n"  ;; OnePlus
    "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"2717\", MODE=\"0660\", TAG+=\"uaccess\"\n"  ;; Xiaomi
    "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"12d1\", MODE=\"0660\", TAG+=\"uaccess\"\n"  ;; Huawei
    "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"0bb4\", MODE=\"0660\", TAG+=\"uaccess\"\n"  ;; HTC
    "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"1004\", MODE=\"0660\", TAG+=\"uaccess\"\n"  ;; LG
    "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"0fce\", MODE=\"0660\", TAG+=\"uaccess\"\n"  ;; Sony
    "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"05c6\", MODE=\"0660\", TAG+=\"uaccess\"\n"  ;; Qualcomm reference
    "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"0e8d\", MODE=\"0660\", TAG+=\"uaccess\"\n"  ;; MediaTek reference
    "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"2b4c\", MODE=\"0660\", TAG+=\"uaccess\"\n"  ;; Nothing
    "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"19d2\", MODE=\"0660\", TAG+=\"uaccess\"\n"  ;; ZTE
    "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"109b\", MODE=\"0660\", TAG+=\"uaccess\"")))  ;; Hisense

;; Allow members of the netdev group to manage NetworkManager without
;; a polkit authentication prompt — needed because niri does not run a
;; polkit authentication agent, so otherwise nmtui/nmcli silently fail
;; to apply changes.
(define %netdev-nm-polkit-rules
  (file-union
   "netdev-nm-polkit-rules"
   `(("share/polkit-1/rules.d/40-netdev-nm.rules"
      ,(plain-file
        "40-netdev-nm.rules"
        "polkit.addRule(function(action, subject) {
    if (action.id.indexOf(\"org.freedesktop.NetworkManager.\") == 0 &&
        subject.isInGroup(\"netdev\")) {
        return polkit.Result.YES;
    }
});
")))))

(operating-system 
  (locale "en_US.utf8")
  (timezone "America/Chicago")
  (keyboard-layout (keyboard-layout "us" 
                                    #:options '("ctrl:nocaps")))
  (host-name "blep")
  (kernel linux)
  (kernel-arguments
   (append
    (list "quiet"
          ;; Prevent the DVB-T driver from claiming RTL2832-based SDR
          ;; dongles so op25 (and other SDR tools) can open them.
          "modprobe.blacklist=dvb_usb_rtl28xxu,rtl2832,rtl2830,rtl2838")
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
   ;; nss-certs is in %base-packages as of recent Guix; do not list
   ;; it explicitly or `guix system` warns about a duplicate.
   (packages (append (list bolt openssh bladerf rtl-sdr airspy cups
			   system-config-printer
			   tailscale tailscaled)
		     ;; Filesystem helpers so udisks (and therefore
		     ;; udiskie automount) can mount removable media
		     ;; formatted as NTFS/exFAT/FAT/F2FS/btrfs.  udisks
		     ;; invokes /run/current-system/profile/sbin/mount.*
		     ;; helpers, which must live in the system profile.
		     (map specification->package
		          (list "ntfs-3g"
		                "exfatprogs"
		                "fuse-exfat"
		                "dosfstools"
		                "f2fs-tools"
		                "btrfs-progs"))
		     %base-packages))

  ;; Below is the list of system services.  To search for available
  ;; services, run 'guix system search KEYWORD' in a terminal.
  (services
   (cons* (service cups-service-type
		   (cups-configuration
		    (web-interface? #f)
		    (extensions
		     (list cups-filters))))
	  (service subids-service-type
                   (subids-configuration
                    (add-root? #f)
                    (subuids (list (subid-range (name "person"))))
                    (subgids (list (subid-range (name "person"))))))
          (service boltd-service-type)
	  ;; Disable when travelling. Bluetooth on hostile networks
	  ;; (e.g. cons) is an unnecessary attack surface.
	  (service bluetooth-service-type
		   (bluetooth-configuration
		    (auto-enable? #t)))
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
			    (command (file-append niri "/bin/niri"))
			    (command-args '())
			    (xdg-session-type "wayland"))))))))))
	  (service screen-locker-service-type
                   (screen-locker-configuration
                   (name "swaylock")
                   (program (file-append swaylock "/bin/swaylock"))
                   (using-pam? #t)
                   (using-setuid? #f)))
	  (udev-rules-service 'bladerf %bladerf-udev-rule)
	  (udev-rules-service 'rtl-sdr rtl-sdr)
	  (udev-rules-service 'airspy airspy)
	  (udev-rules-service 'monome %monome-udev-rule)
	  ;; Picotool ships its own 60-picotool.rules under
	  ;; lib/udev/rules.d/; the rule uses TAG+="uaccess" so any
	  ;; active-seat user gets BOOTSEL access via elogind — no
	  ;; extra group membership needed.
	  (udev-rules-service 'picotool picotool)
	  ;; Saleae Logic ships its 99-SaleaeLogic{,-v1}.rules under
	  ;; lib/udev/rules.d/ — rules set MODE="0666" on the logic
	  ;; analyzer USB VID/PIDs so the Logic app can open the device
	  ;; without root.
	  (udev-rules-service 'saleae-logic saleae-logic)
	  (udev-rules-service 'debugprobe %debugprobe-udev-rule)
	  (udev-rules-service 'flipperzero %flipperzero-udev-rule)
	  (udev-rules-service 'android %android-udev-rule)
	  (udev-hardware-service 'capslock %capslock-hwdb-udev-rule)
	  (simple-service 'netdev-nm-polkit
			  polkit-service-type
			  (list %netdev-nm-polkit-rules))
	  audio-realtime-service
	  ;; Disabled for travel — this service applies an
	  ;; ACCEPT-everything iptables ruleset (see the
	  ;; `%iptables-accept-all-rules` default in
	  ;; gnu/services/networking.scm) which fights with
	  ;; nftables-service-type's drop-by-default policy.
	  ;; Rootless podman with passt/slirp4netns doesn't need
	  ;; host iptables rules. Re-enable (with an explicit
	  ;; ruleset) if you go back to rootful containers.
	  ;; podman-iptables
	  (service tailscale-service-type)
           ;; This is the default list of services we
           ;; are appending to.
	  (modify-services %desktop-services
		 (delete gdm-service-type)
		 ;; Disabled for travel — mDNS broadcasts the hostname
		 ;; and advertised services on every network you join.
		 (delete avahi-service-type)
		 ;; Disabled for travel — Guix's ntp-configuration has
		 ;; no interface-binding option so ntpd binds
		 ;; 0.0.0.0:123 (and every up interface, including
		 ;; tailscale0). A few days of clock drift is fine.
		 ;; (delete ntp-service-type)
		 ;; Guix's NetworkManager is built with
		 ;; --with-resolvconf=<openresolv store path>, so its
		 ;; default rc-manager=auto picks "resolvconf" and hands
		 ;; DNS updates to a binary that isn't running as a
		 ;; service — /etc/resolv.conf never gets written and
		 ;; DNS silently breaks. Force NM to write the file
		 ;; directly.
		 (network-manager-service-type config =>
		   (network-manager-configuration
		    (inherit config)
		    (extra-configuration-files
		     `(("rc-manager.conf"
			,(plain-file "rc-manager.conf"
				     "[main]\nrc-manager=file\n"))))))
		 (guix-service-type config =>
		   (guix-configuration
		    (inherit config)
		    (substitute-urls
		     ;; Disabled for travel — http and leaks the name
		     ;; of every package you pull to whoever's on the
		     ;; network path. Restore after the trip:
		     ;;   (cons "http://guix.xk.is" %default-substitute-urls)
		     %default-substitute-urls)
		    (authorized-keys
		     (cons (local-file "../../../configs/xk-substitutes.pub")
			   %default-authorized-guix-keys)))))))
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
