(define-module (noonker home theme)
  #:use-module (gnu bootloader grub)
  #:use-module (gnu home services)
  #:use-module (gnu packages fonts)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gnome-xyz)
  #:use-module (gnu packages xorg)
  #:use-module (gnu services)
  #:use-module (guix build-system trivial)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (ice-9 match)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 regex)
  #:use-module (noonker packages shaderbg)
  #:use-module (srfi srfi-1)
  #:export (desktop-theme-service
            desktop-grub-theme))

;;; One palette per mode; every themed application's config is generated from
;;; these by filling in the templates in ./theme/.  `theme-switch' then points
;;; ~/.local/state/theme/current at ~/.config/theme/{day,night}, which is what
;;; the applications' own (read-only) configs include.

;; Where the sky is seen from, by the background shaders and by darkman.
(define %latitude "44.5")
(define %longitude "-88.0")

;; Tarot de Marseille: sampled from a hand-stencilled woodcut deck.  Its pale
;; yellow-green and pink don't work as text, so those roles use darker versions.
(define %day-palette
  '((pattern . "hatch")
    (font . "Comic Code") (font-bold . "Comic Code Bold")
    (font-italic . "Comic Code Italic")
    (font-bold-italic . "Comic Code Bold Italic")
    (ui-font . "Comic Code")
    (book-font . "Cardo")
    (paper . "#f7f4e8") (fold . "#575b40") (rule . "#0c121a") (book-ink . "#0c121a")
    (bg . "#f2f0e4") (bg-alt . "#e8e3d2") (bg-high . "#dfcfc7") ; card, flesh tint
    (fg . "#0c121a") (fg-dim . "#575b40")
    (accent . "#9d2606")                ; vermilion
    (accent2 . "#ad3156")               ; the crosshatched card back
    (sun . "#d4d65d")                   ; stencilled yellow-green, not for text
    (sky . "#5377c0")                   ; stencilled cobalt, not for text
    (rouge . "#d8452a")                 ; stencilled red, not for text
    (ochre . "#e1bd5c")                 ; the sun's ring and rays, not for text
    (olive . "#a8953f")                 ; its disc, a little lighter than the card's
    (moss . "#5e6340")                  ; the wall's green, not for text
    (card-rule . "#0c121a") (card-rule-cut . "rough") ; black, hand-cut
    (black . "#0c121a") (red . "#9d2606") (green . "#3f5a12")
    (yellow . "#635e00") (blue . "#2f538c") (magenta . "#ad3156")
    (cyan . "#1f6470") (orange . "#a4480c") (white . "#bcb8b4")
    (bright-black . "#575b40") (bright-red . "#b02c0a")
    (bright-green . "#4a6516") (bright-yellow . "#6b6600")
    (bright-blue . "#3a5f9c") (bright-magenta . "#b23459")
    (bright-cyan . "#256e7b") (bright-white . "#fcfdf9")))

;; Arcana: the night sky on the back of a tarot deck.
(define %night-palette
  '((pattern . "stars")
    ;; The "A" cut is the only strictly fixed-pitch one, but it has no bold.  The
    ;; plain family's y and z are narrower, so it's only used where the grid
    ;; doesn't matter; its bold has the same cell width as A.  Neither has italics.
    (font . "New Heterodox Mono A") (font-bold . "New Heterodox Mono Bold")
    (font-italic . "auto")
    (font-bold-italic . "New Heterodox Mono Bold")
    (ui-font . "New Heterodox Mono")
    (book-font . "Junicode")
    (paper . "#1c1238") (fold . "#05020d") (rule . "#e8c46a") (book-ink . "#e6dff8")
    (bg . "#110a24") (bg-alt . "#1c1238") (bg-high . "#2f2058")
    (fg . "#e6dff8") (fg-dim . "#9c8fc6")
    (accent . "#e8c46a")                ; gold leaf
    (accent2 . "#b388ff")               ; violet
    (card-rule . "#e8c46a") (card-rule-cut . "fine") ; gold leaf, ruled clean
    (black . "#241845") (red . "#f0708f") (green . "#86d6a6")
    (yellow . "#e8c46a") (blue . "#86a5f7") (magenta . "#c08cf5")
    (cyan . "#79dcea") (orange . "#f2a36b") (white . "#cfc6e8")
    (bright-black . "#8072b0") (bright-red . "#ff8fa8")
    (bright-green . "#a6efc2") (bright-yellow . "#ffe08f")
    (bright-blue . "#a8c0ff") (bright-magenta . "#d8b0ff")
    (bright-cyan . "#a0efff") (bright-white . "#fbf8ff")))

;;; Bar icons.  These are Pango markup, so a mode can dress its glyphs.

(define %icon-line-height "0.2")

(define (color-of palette key)
  (assq-ref palette key))

(define (icon-list . icons)
  "The inside of a JSON array, for a format-icons entry."
  (string-join (map (lambda (icon) (string-append "\"" icon "\"")) icons) ", "))

;; Alchemy, in black ink; waybar-day.css.in paints the stencil color behind it.
;;
;; A label's line takes its height and baseline from every font on it, and each module
;; is centered on its own, so an icon from a font with other metrics moves that module's
;; text (Noto Sans Symbols has a line height of 2em).  A small line_height stops the
;; icons having any say, which keeps all the text level.  RISE then centers the glyph.
(define* (ink glyph #:optional (rise "-2048"))
  (string-append "<span line_height='" %icon-line-height "' rise='" rise "'><big>"
                 glyph "</big></span> "))

(define %day-icons
  `(;; The numerals at the head of a card.
    (icon-ws-1 . "I") (icon-ws-2 . "II") (icon-ws-3 . "III") (icon-ws-4 . "IV")
    (icon-ws-5 . "V") (icon-ws-6 . "VI") (icon-ws-7 . "VII") (icon-ws-8 . "VIII")
    (icon-ws-9 . "IX") (icon-ws-10 . "X")
    (icon-clock . ,(ink "🝮"))        ; hour
    (icon-date . ,(ink "🝱"))         ; month
    (icon-uptime . ,(ink "🝰"))       ; day-night
    (icon-cpu . ,(ink "🜂"))        ; fire
    (icon-memory . ,(ink "🜔"))       ; salt, which preserves
    (icon-temperature . ,(ink "🜍")) ; sulfur, brimstone
    (icon-disk . ,(ink "🜃"))     ; earth, where things are buried
    (icon-disk-io . ,(ink "🜄"))      ; water, which flows
    (icon-wifi . ,(ink "🜁"))         ; air
    (icon-ethernet . ,(ink "♀"))    ; Venus, copper
    (icon-offline . ,(ink "🝎"))  ; caput mortuum, the dead head
    (icon-audio . ,(ink "🔔" "0"))        ; the bell, of bell, book and candle
    (icon-muted . ,(ink "🔕" "0"))
    (icon-bluetooth . ,(ink "🝐"))    ; caduceus, the messenger's staff
    (icon-brightness . ,(icon-list (ink "☉"))) ; the sun, gold
    (icon-battery . ,(icon-list (ink "🝆"))) ; oil, for the lamp
    (icon-charging . ,(ink "☇ "))    ; thunderbolt
    (icon-updates . ,(ink "🝞"))      ; sublimation
    (icon-quote . ,(ink "⛤"))     ; the pentagram tells your fortune
    (icon-player . ,(ink "⚚"))        ; Hermes' staff
    (icon-lock . ,(ink "👁" "0"))     ; the eye that doesn't close
    (icon-unlock . ,(ink "⛤"))))

;; Astronomy.  Glyphs in gold leaf, from the Nerd Font's sky.
(define (gold glyph)
  (string-append "<span color='" (color-of %night-palette 'accent)
                 "' line_height='" %icon-line-height "'><big>" glyph "</big></span>"))

(define %night-icons
  `(;; The solar system, in order from the sun.
    (icon-ws-1 . "<big>☉</big>") (icon-ws-2 . "<big>☿</big>") (icon-ws-3 . "<big>♀</big>")
    (icon-ws-4 . "<big>♁</big>") (icon-ws-5 . "<big>♂</big>") (icon-ws-6 . "<big>♃</big>")
    (icon-ws-7 . "<big>♄</big>") (icon-ws-8 . "<big>♅</big>") (icon-ws-9 . "<big>♆</big>")
    (icon-ws-10 . "<big>♇</big>")
    ;; Only things you could find in the sky: no instruments, and nothing we launched.
    (icon-clock . ,(gold "\U0f0594"))          ; crescent and stars
    (icon-date . ,(gold "\U0f0f61"))           ; a month is a moon
    (icon-uptime . ,(gold "\U0f0018"))         ; orbit
    (icon-cpu . ,(gold "\U0f0599"))            ; the sun
    (icon-memory . ,(gold "\U0f0674"))         ; a cluster of stars
    (icon-temperature . ,(gold "\U0f0d72"))    ; solar flare
    (icon-disk . ,(gold "\U0f01e7"))           ; the earth
    (icon-disk-io . ,(gold "\U0f0629"))        ; meteor
    (icon-wifi . ,(gold "\U0f1741"))           ; shooting star
    (icon-ethernet . ,(gold "☌"))              ; conjunction: two bodies joined
    (icon-offline . ,(gold "\U0f01e8"))        ; the earth, dark
    (icon-audio . ,(gold "\U0f15db"))          ; the music of the spheres
    (icon-muted . ,(gold "\U0f0f64"))          ; new moon
    (icon-bluetooth . ,(gold "☽"))             ; the moon: the near neighbour
    ;; Three stars brightening.
    (icon-brightness . ,(icon-list (gold "\U0f04d2") (gold "\U0f04d0") (gold "\U0f0ae2")))
    ;; The moon fills as the battery does.
    (icon-battery . ,(icon-list (gold "\U0f0f64") (gold "\U0f0f67") (gold "\U0f0f61")
                                (gold "\U0f0f68") (gold "\U0f0f62")))
    (icon-charging . ,(gold "\U0f1545"))       ; sparkling
    (icon-updates . ,(gold "☄"))               ; a comet: it comes back
    (icon-quote . ,(gold "\U0f04cf"))          ; read it in the stars
    (icon-player . ,(gold "♆"))                ; Neptune
    (icon-lock . ,(gold "\U0f0f62"))           ; full moon: nobody sleeps
    (icon-unlock . ,(gold "\U0f0f64"))))

(define %day (append %day-icons %day-palette))
(define %night (append %night-icons %night-palette))

;; Template name -> generated file name.
(define %templates
  '(("kitty.conf.in" . "kitty.conf")
    ("waybar.jsonc.in" . "waybar.jsonc")
    ("waybar.css.in" . "waybar.css")
    ("rofi.rasi.in" . "rofi.rasi")
    ("deck-notify.conf.in" . "deck-notify.conf")
    ("swaylock.conf.in" . "swaylock.conf")
    ("book.conf.in" . "book.conf")
    ("emacs.el.in" . "emacs.el")))

(define (theme-file name)
  (or (search-path %load-path (string-append "noonker/home/theme/" name))
      (error "theme file not found:" name)))

(define (read-template name)
  (call-with-input-file (theme-file name) read-string #:encoding "UTF-8"))

(define (hex->vec3 hex)
  "Turn \"#rrggbb\" into the GLSL arguments \"r, g, b\"."
  (define (channel start)
    (number->string
     (exact->inexact
      (/ (string->number (substring hex start (+ start 2)) 16) 255))))
  (string-append (channel 1) ", " (channel 3) ", " (channel 5)))

(define (render palette template)
  "Replace %key% (or %key.vec3%) in TEMPLATE with the colors from PALETTE."
  (regexp-substitute/global
   #f "%([a-z0-9-]+)(\\.vec3)?%" template
   'pre
   (lambda (m)
     (let* ((key (string->symbol (match:substring m 1)))
            (value (or (assq-ref palette key)
                       (error "unknown palette key:" key))))
       (if (match:substring m 2) (hex->vec3 value) value)))
   'post))

;; The lock screen's cards: Jean Dodal's Tarot de Marseille, Lyon, 1701-1715, from the
;; BnF's scans via Wikimedia Commons (public domain, PD-old-70):
;;   https://commons.wikimedia.org/wiki/File:Jean_Dodal_M00.jpg  (Le Fol), and so on to M21
;; Each mode's own card is the image in its swaylock.conf, for when theme-lock can't
;; find today's.  `theme-card' picks today's, and has their names and meanings.
(define %lock-cards
  '(("day" . 0)
    ("night" . 18)))

(define (card-file number)
  (theme-file (match number
                (0 "lock-fool.jpg")
                (18 "lock-moon.jpg")
                (_ (string-append "cards/" (card-name number) ".jpg")))))

(define (card-name number)
  (string-append (if (< number 10) "0" "") (number->string number)))

(define (card-scene kind mode palette number)
  "The mode's scene of KIND, \"lock\" or \"book\" (an SVG template), around card NUMBER."
  (let ((card (local-file (card-file number)
                          (string-append "card-" (card-name number) ".jpg")))
        (scene (plain-file (string-append kind "-" mode ".svg")
                           (render palette
                                   (read-template
                                    (string-append kind "-" mode ".svg.in"))))))
    (computed-file
     (string-append "theme-" mode "-" kind "-" (card-name number) ".png")
     (with-imported-modules '((guix build utils))
       #~(begin
           (use-modules (guix build utils))
           ;; librsvg only follows an href to a file beside the SVG.
           (copy-file #$scene "scene.svg")
           (copy-file #$card "card.jpg")
           (invoke #+(file-append librsvg "/bin/rsvg-convert")
                   "-o" #$output "scene.svg"))))))

;; The boot menu is always at night: La Lune and the sky, with GRUB's nearest colors.
(define desktop-grub-theme
  (grub-theme
   (image
    (let ((card (local-file (card-file 18) "card-18.jpg"))
          (scene (plain-file "grub.svg"
                             (render %night (read-template "grub.svg.in")))))
      (computed-file
       "theme-grub.png"
       (with-imported-modules '((guix build utils))
         #~(begin
             (use-modules (guix build utils))
             ;; librsvg only follows an href to a file beside the SVG.
             (copy-file #$scene "grub.svg")
             (copy-file #$card "card.jpg")
             (invoke #+(file-append librsvg "/bin/rsvg-convert")
                     "-o" #$output "grub.svg"))))))
   (color-normal '((fg . light-gray) (bg . black)))
   (color-highlight '((fg . yellow) (bg . black)))))

(define (background-shader mode palette)
  "The mode's background shader, with the files it includes and where it's seen from."
  (plain-file (string-append "theme-" mode "-background.frag")
              (render `((latitude . ,%latitude)
                        (longitude . ,%longitude)
                        (background-common . ,(read-template "background-common.glsl"))
                        (sky-table . ,(read-template "sky-table.glsl"))
                        ,@palette)
                      (read-template (string-append "background-" mode ".frag.in")))))

(define (niri-config mode palette)
  "The shared niri settings, and the mode's window animations with their shaders in."
  (define (shader file)
    (render palette (read-template file)))
  (string-append
   (render palette (read-template "niri.kdl.in"))
   (fold (match-lambda*
           (((key . file) text)
            (regexp-substitute/global #f key text 'pre (shader file) 'post)))
         (read-template (string-append "niri-" mode ".kdl.in"))
         '(("%card-turn-shader%" . "niri-card-turn.glsl.in")
           ("%gold-dust-shader%" . "niri-gold-dust.glsl.in")))))

(define (mode-files mode palette)
  (define (generated template target)
    (list (string-append "theme/" mode "/" target)
          (plain-file (string-append "theme-" mode "-" target)
                      (render palette (read-template template)))))
  ;; Rendered ahead of time, since each takes a second or two.
  (define (scene kind directory number)
    (list (string-append "theme/" mode "/" directory "/" (card-name number) ".png")
          (card-scene kind mode palette number)))
  (cons* (list (string-append "theme/" mode "/background.frag")
               (background-shader mode palette))
         (list (string-append "theme/" mode "/lock.png")
               (card-scene "lock" mode palette (assoc-ref %lock-cards mode)))
         (list (string-append "theme/" mode "/niri.kdl")
               (plain-file (string-append "theme-" mode "-niri.kdl")
                           (niri-config mode palette)))
         (list (string-append "theme/" mode "/chime.wav")
               (local-file (theme-file (string-append "sounds/chime-" mode ".wav"))))
         (list (string-append "theme/" mode "/lock.wav")
               (local-file (theme-file (string-append "sounds/lock-" mode ".wav"))))
         (append
          (map (lambda (number) (scene "lock" "cards" number)) (iota 22))
          (map (lambda (number) (scene "book" "book" number)) (iota 22))
          (map (match-lambda ((template . target) (generated template target)))
               (append `((,(string-append "waybar-" mode ".css.in") . "waybar-look.css")
                         (,(string-append "waybar-" mode ".svg.in") . "waybar.svg"))
                       %templates)))))

(define %theme-switch
  (local-file "theme/theme-switch" "theme-switch" #:recursive? #t))

(define %theme-lock
  (local-file "theme/theme-lock" "theme-lock" #:recursive? #t))

(define %theme-background
  (local-file "theme/theme-background" "theme-background" #:recursive? #t))

(define %theme-book
  (local-file "theme/theme-book" "theme-book" #:recursive? #t))

(define %theme-card
  (local-file "theme/theme-card" "theme-card" #:recursive? #t))

(define %darkman-config
  ;; Darkman only decides when to switch; theme-switch does the rest, including
  ;; the gsettings change that the GTK portal passes on to applications.
  (plain-file "darkman-config.yaml"
              (string-append "lat: " %latitude "\nlng: " %longitude
                             "\nusegeoclue: false\nportal: false\n")))

(define %theme-activation
  ;; The configs include the pointer, and niri rejects its whole config if an
  ;; include is missing, so it must exist before anything reads them.  Darkman
  ;; corrects the mode as soon as it starts.
  #~(let* ((home (getenv "HOME"))
           (state (string-append home "/.local/state/theme"))
           (current (string-append state "/current")))
      (for-each (lambda (dir)
                  (unless (file-exists? dir)
                    (mkdir dir)))
                (list (string-append home "/.local")
                      (string-append home "/.local/state")
                      state))
      (unless (false-if-exception (lstat current))
        (symlink (string-append home "/.config/theme/night") current))))

;; The one Firefox stylesheet carries both palettes, so Firefox switches by itself
;; when the desktop's color scheme changes.
(define %firefox-profile ".mozilla/firefox/w3i5txwl.default-1767125790655")

(define (firefox-mode scheme palette)
  (string-append "@media (prefers-color-scheme: " scheme ") {\n"
                 (render palette (read-template "firefox.css.in"))
                 "}\n"))

(define %firefox-user-chrome
  (plain-file "userChrome.css"
              (string-append (firefox-mode "light" %day)
                             (firefox-mode "dark" %night))))

(define %firefox-user-js
  (plain-file "user.js"
              "user_pref(\"toolkit.legacyUserProfileCustomizations.stylesheets\", true);\n"))

;; The alchemical symbols on the day bar.  This is the only family they need, and
;; font-google-noto is 290 MB of them, which would also change every font fallback.
(define font-noto-sans-symbols
  (package
    (name "font-noto-sans-symbols")
    (version (package-version font-google-noto))
    (source #f)
    (build-system trivial-build-system)
    (arguments
     (list #:modules '((guix build utils))
           #:builder
           #~(begin
               (use-modules (guix build utils))
               (install-file #$(file-append font-google-noto
                                            "/share/fonts/opentype/NotoSansSymbols-Regular.otf")
                             (string-append #$output "/share/fonts/opentype")))))
    (home-page (package-home-page font-google-noto))
    (synopsis "Noto Sans Symbols font")
    (description "The Noto Sans Symbols family alone, from font-google-noto.")
    (license (package-license font-google-noto))))

;;; GTK.  adw-gtk3 builds its widgets from the same named colors as libadwaita, so one
;;; table of roles can dress both toolkits.

(define %gtk-colors
  '(("accent_bg_color" . accent) ("accent_fg_color" . bg) ("accent_color" . accent)
    ("destructive_bg_color" . red) ("destructive_fg_color" . bg) ("destructive_color" . red)
    ("success_bg_color" . green) ("success_fg_color" . bg) ("success_color" . green)
    ("warning_bg_color" . yellow) ("warning_fg_color" . bg) ("warning_color" . yellow)
    ("error_bg_color" . red) ("error_fg_color" . bg) ("error_color" . red)
    ("window_bg_color" . bg) ("window_fg_color" . fg)
    ("view_bg_color" . bg) ("view_fg_color" . fg)
    ("headerbar_bg_color" . bg-alt) ("headerbar_fg_color" . fg)
    ("headerbar_border_color" . card-rule) ("headerbar_backdrop_color" . bg)
    ("sidebar_bg_color" . bg-alt) ("sidebar_fg_color" . fg)
    ("sidebar_backdrop_color" . bg)
    ("card_bg_color" . bg-alt) ("card_fg_color" . fg)
    ("dialog_bg_color" . bg) ("dialog_fg_color" . fg)
    ("popover_bg_color" . bg-alt) ("popover_fg_color" . fg)
    ("thumbnail_bg_color" . bg-alt) ("thumbnail_fg_color" . fg)))

(define (gtk-colors palette format-color)
  (string-concatenate
   (map (match-lambda
          ((name . key) (format-color name (assq-ref palette key))))
        %gtk-colors)))

(define (gtk3-theme adw-name palette)
  "A GTK 3 theme: adw-gtk3 in PALETTE's colors.  It has to be a theme, not ~/.config's
gtk.css, because only a theme is reloaded when it changes: the polkit agent runs all day."
  (mixed-text-file
   "gtk.css"
   "@import url(\"" adw-gtk3-theme "/share/themes/" adw-name "/gtk-3.0/gtk.css\");\n"
   (gtk-colors palette
               (lambda (name color)
                 (string-append "@define-color " name " " color ";\n")))
   (render palette (read-template "gtk.css.in"))))

(define (gtk4-theme base palette)
  "Plain GTK 4 applications take a theme, and libadwaita ignores it."
  (plain-file
   "gtk.css"
   (string-append "@import url(\"resource:///org/gtk/libgtk/theme/Default/" base ".css\");\n"
                  (render palette (read-template "gtk4-plain.css.in")))))

(define (gtk4-mode scheme palette)
  (string-append
   "@media (prefers-color-scheme: " scheme ") {\n:root {\n"
   (gtk-colors palette
               (lambda (name color)
                 (string-append "--"
                                (string-map (lambda (c) (if (char=? c #\_) #\- c)) name)
                                ": " color ";\n")))
   "}\n"
   (render palette (read-template "gtk.css.in"))
   "}\n"))

;; For libadwaita, which ignores the theme but follows the color scheme by itself.
(define %gtk4-css
  (plain-file "gtk.css"
              (string-append (gtk4-mode "light" %day)
                             (gtk4-mode "dark" %night))))

;;; Cursors.  Only the ones you see all day are drawn; the rest, like the resize arrows,
;;; come from Adwaita through Inherits.

;; Name, hotspot in the SVGs' 64-unit square, frames, and the names it also goes by.
(define %cursors
  '(("default" 5 4 1 "left_ptr" "arrow" "top_left_arrow")
    ("pointer" 5 4 1 "hand" "hand1" "hand2" "pointing_hand")
    ("text" 32 32 1 "xterm" "ibeam")
    ("wait" 32 32 12 "watch" "progress" "left_ptr_watch" "half-busy")))

;; niri multiplies its xcursor-size of 34 by the output's scale of 1.5, so 51 is what the
;; laptop's screen shows.  The others are for scales 1 and 2, and for larger settings.
(define %cursor-sizes '(24 34 48 51 68 102))

(define (cursor-frame mode palette name frame frames)
  "FRAME of FRAMES of cursor NAME, as an SVG; @angle@ is how far round it has turned."
  (plain-file
   (string-append "cursor-" mode "-" name "-" (number->string frame) ".svg")
   (regexp-substitute/global
    #f "@angle@"
    (render palette (read-template (string-append "cursors/" mode "-" name ".svg.in")))
    'pre (number->string (/ (* frame 360) frames)) 'post)))

(define (cursor-theme theme mode palette)
  (computed-file
   (string-append "cursor-theme-" theme)
   (with-imported-modules '((guix build utils))
     #~(begin
         (use-modules (guix build utils)
                      (ice-9 format)
                      (ice-9 match))
         (define cursors (string-append #$output "/cursors"))
         (mkdir-p cursors)
         (call-with-output-file (string-append #$output "/index.theme")
           (lambda (port)
             (format port "[Icon Theme]\nName=~a\nInherits=Adwaita\n" #$theme)))
         (for-each
          (match-lambda
            ((name hot-x hot-y aliases frames)
             (call-with-output-file "cursor.cfg"
               (lambda (port)
                 (for-each
                  (lambda (size)
                    (let loop ((frames frames) (number 0))
                      (match frames
                        (() #t)
                        ((frame . rest)
                         (let ((png (format #f "~a-~a-~a.png" name size number)))
                           (invoke #+(file-append librsvg "/bin/rsvg-convert")
                                   "-w" (number->string size)
                                   "-h" (number->string size)
                                   "-o" png frame)
                           (format port "~a ~a ~a ~a 90\n" size
                                   (round (/ (* hot-x size) 64))
                                   (round (/ (* hot-y size) 64))
                                   png))
                         (loop rest (+ number 1))))))
                  '#$%cursor-sizes)))
             (invoke #+(file-append xcursorgen "/bin/xcursorgen")
                     "cursor.cfg" (string-append cursors "/" name))
             (for-each (lambda (alias)
                         (symlink name (string-append cursors "/" alias)))
                       aliases)))
          (list
           #$@(map (match-lambda
                     ((name hot-x hot-y frames . aliases)
                      #~(list #$name #$hot-x #$hot-y '#$aliases
                              (list #$@(map (lambda (frame)
                                              (cursor-frame mode palette name
                                                            frame frames))
                                            (iota frames))))))
                   %cursors)))))))

;; A list, since these extend several services.
(define desktop-theme-service
  (list
   (simple-service 'desktop-theme-config
                   home-xdg-configuration-files-service-type
                   (cons* (list "darkman/config.yaml" %darkman-config)
                          (list "gtk-4.0/gtk.css" %gtk4-css)
                          (append (mode-files "day" %day)
                                  (mode-files "night" %night))))
   (simple-service 'desktop-theme-fonts
                   home-profile-service-type
                   (list font-noto-sans-symbols font-cardo font-junicode shaderbg-baked))
   (simple-service 'desktop-theme-scripts
                   home-files-service-type
                   (list (list "bin/theme-switch" %theme-switch)
                         (list "bin/theme-lock" %theme-lock)
                         (list "bin/theme-card" %theme-card)
                         (list "bin/theme-book" %theme-book)
                         (list "bin/theme-background" %theme-background)
                         (list ".icons/Marseille" (cursor-theme "Marseille" "day" %day))
                         (list ".icons/Arcana" (cursor-theme "Arcana" "night" %night))
                         (list ".local/share/themes/Marseille/gtk-3.0/gtk.css"
                               (gtk3-theme "adw-gtk3" %day))
                         (list ".local/share/themes/Marseille/gtk-4.0/gtk.css"
                               (gtk4-theme "Default-light" %day))
                         (list ".local/share/themes/Arcana/gtk-3.0/gtk.css"
                               (gtk3-theme "adw-gtk3-dark" %night))
                         (list ".local/share/themes/Arcana/gtk-4.0/gtk.css"
                               (gtk4-theme "Default-dark" %night))
                         ;; Run by darkman with "light" or "dark".
                         (list ".local/share/darkman/theme-switch" %theme-switch)
                         (list (string-append %firefox-profile "/chrome/userChrome.css")
                               %firefox-user-chrome)
                         (list (string-append %firefox-profile "/user.js")
                               %firefox-user-js)))
   (simple-service 'desktop-theme-pointer
                   home-activation-service-type
                   %theme-activation)))
