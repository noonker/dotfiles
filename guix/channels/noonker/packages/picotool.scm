;; picotool: Raspberry Pi's official RP2040/RP2350 host-side tool.
;;
;; Used from Rust-embedded projects (e.g. furbtar) as the `cargo run`
;; runner via `picotool load -u -v -x -t elf`, which talks USB directly
;; to a Pico in BOOTSEL and reboots into the flashed image on success.
;; Also reads `.bi_entries` binary-info via `picotool info`.
;;
;; upstream `elf2uf2-rs` (as of 2.2.0) does not know the RP2350 UF2
;; family_id (0xe48bff59); its output is silently rejected by the
;; RP2350 bootrom. Use picotool instead.
;;
;; pico-sdk is packaged here only because picotool needs its CMake
;; helpers at build time. We build with PICOTOOL_NO_LIBUSB=0 so the
;; USB backend is enabled.

(define-module (noonker packages picotool)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages)
  #:use-module (gnu packages cmake)
  #:use-module (gnu packages libusb)
  #:use-module (gnu packages pkg-config)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module (guix build-system copy)
  #:use-module (guix build-system cmake))

(define-public pico-sdk
  (package
    (name "pico-sdk")
    (version "2.3.0")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/raspberrypi/pico-sdk.git")
                    (commit version)
                    ;; Submodules (tinyusb, cyw43-driver, etc.) are only
                    ;; needed to build MCU firmware, not for picotool's
                    ;; host build. Keep the tree small.
                    (recursive? #f)))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "1qxjp6p7zl0ng8n5y1jx2qdnf1a2yb3yn68banp89fh34qwrwlj0"))))
    (build-system copy-build-system)
    (arguments
     (list
      #:install-plan
      #~'(("." "share/pico-sdk"))))
    (home-page "https://github.com/raspberrypi/pico-sdk")
    (synopsis "Raspberry Pi Pico SDK (source tree)")
    (description
     "The Raspberry Pi Pico SDK, installed as a source tree under
@file{share/pico-sdk}.  This package exists to satisfy @code{picotool}'s
build-time @env{PICO_SDK_PATH} requirement; the SDK is not built here
because picotool only consumes its CMake helper modules and headers.
For MCU firmware development the SDK is typically consumed directly
from a source checkout rather than via Guix.")
    (license license:bsd-3)))

(define-public picotool
  (package
    (name "picotool")
    (version "2.3.0")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/raspberrypi/picotool.git")
                    (commit version)
                    (recursive? #f)))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "1vp043dp6smc96hxfxrc514pl6ksxmn6akb3szf4ig0yvh4ibnf3"))))
    (build-system cmake-build-system)
    (arguments
     (list
      #:tests? #f                       ;no test suite
      #:configure-flags
      #~(list (string-append "-DPICO_SDK_PATH="
                             #$pico-sdk "/share/pico-sdk")
              "-DCMAKE_BUILD_TYPE=Release")
      #:phases
      #~(modify-phases %standard-phases
          ;; picotool's own CMakeLists doesn't ship an `install` target
          ;; by default; the binary is emitted at build/picotool and
          ;; nothing else. Install it manually, along with the udev
          ;; rules — the latter get picked up by udev-service-type
          ;; when this package is used as an argument to
          ;; udev-rules-service.
          (replace 'install
            (lambda _
              (install-file "picotool"
                            (string-append #$output "/bin"))
              (install-file (string-append #$source
                                           "/udev/60-picotool.rules")
                            (string-append #$output
                                           "/lib/udev/rules.d")))))))
    (native-inputs (list cmake pkg-config))
    (inputs (list libusb))
    (home-page "https://github.com/raspberrypi/picotool")
    (synopsis "Raspberry Pi Pico host-side tool")
    (description
     "@code{picotool} is Raspberry Pi's official host-side tool for
inspecting, converting, and flashing binaries for the RP2040 and
RP2350.  It talks directly to a Pico in BOOTSEL mode over USB (no
mounted mass-storage volume required) and understands the RP2350 UF2
family IDs, unlike @code{elf2uf2-rs} 2.2.0.  Common uses:
@itemize
@item @code{picotool load -u -v -x -t elf firmware.elf} — flash and
      reboot in one step (the default runner for embedded Rust
      projects targeting the Pico 2).
@item @code{picotool info firmware.elf} — decode @code{.bi_entries}
      binary-info metadata.
@item @code{picotool reboot -u} — toggle a running Pico into
      BOOTSEL without unplugging.
@end itemize
Ships udev rules under @file{lib/udev/rules.d/} for optional
rootless USB access.")
    (license license:bsd-3)))

picotool
