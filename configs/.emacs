;;; .emacs -- WIP emacs configuration
;-*-Emacs-Lisp-*-

;;; Commentary:
;;
;; I'm just here so I won't get fined
;;
;;; Code:

;; Set up repos and ensure desired files are installed
(require 'package)

(add-to-list 'package-archives '("org" . "http://orgmode.org/elpa/"))
(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/"))
(add-to-list 'package-archives '("melpa-stable" . "http://stable.melpa.org/packages/"))

(setq package-enable-at-startup nil)
(package-initialize)

(defun ensure-package-installed (&rest packages)
  "Assure every package is installed, ask for installation if it’s not.

Return a list of installed packages or nil for every skipped package."
  (mapcar
   (lambda (package)
     (if (package-installed-p package)
         nil
       (if (y-or-n-p (format "Package %s is missing. Install it? " package))
           (package-install package)
         package)))
   packages))

;; Make sure to have downloaded archive description.
(or (file-exists-p package-user-dir)
    (package-refresh-contents))

;; Activate installed packages
(package-initialize)

;; Set exec-path
;; (when (memq window-system '(mac ns x))
;;  (exec-path-from-shell-initialize))

;; Assuming you wish to install "iedit" and "magit"
(ensure-package-installed 'iedit
                          'magit
                          'flycheck
                          'helm
                          'powerline
                          '2048-game
                          'projectile
                          'helm-projectile
                          'org
                          'org-plus-contrib
                          'helm-ag
                          'company
                          'autopair
                          'twittering-mode
                          'wttrin
                          'fireplace
                          'ensime
                          'dumb-jump
                          'es-mode
                          'restclient
                          'exec-path-from-shell
                          'monokai-theme
                          'excorporate
                          'hackernews
                          'notmuch
                          'xclip
                          'evil
                          'w3m
                          'mediawiki
                          'erc-colorize
                          'mingus
                          'column-marker
                          'emojify
                          'minimap
                          'request
			  'adaptive-wrap
			  'multiple-cursors
			  'isend-mode
			  'pcap-mode
			  'exwm
			  'firefox-controller
			  'icicles
			  'ace-popup-menu
			  'ipcalc
			  )


;;(evil-mode t)
(global-flycheck-mode)
;;(global-linum-mode t)
(powerline-default-theme)
(global-company-mode)

;; Python iPython
(setq
 python-shell-interpreter "ipython"
 python-shell-interpreter-args "--colors=Linux --profile=default"
 python-shell-prompt-regexp "In \\[[0-9]+\\]: "
 python-shell-prompt-output-regexp "Out\\[[0-9]+\\]: "
 python-shell-completion-setup-code
 "from IPython.core.completerlib import module_completion"
 python-shell-completion-module-string-code
 "';'.join(module_completion('''%s'''))\n"
 python-shell-completion-string-code
 "';'.join(get_ipython().Completer.all_completions('''%s'''))\n")

;; erc-colors
(erc-colorize-mode 1)

(global-set-key (kbd "M-x") 'helm-M-x)
(global-set-key (kbd "M-x") #'helm-M-x)
(global-set-key (kbd "C-x r b") #'helm-filtered-bookmarks)
(global-set-key (kbd "C-x C-f") #'helm-find-files)
(helm-mode 1)

(setq projectile-completion-system 'helm)
(setq projectile-enable-caching t)
(helm-projectile-on)
(setq linum-format "%d ")

(set-face-attribute 'flycheck-warning nil
                    :foreground "black"
                    :background "yellow")
(set-face-attribute 'flycheck-error nil
                    :foreground "black"
                    :background "red")
(set-face-attribute 'flycheck-info nil
                    :foreground "black"
                    :background "green")

;;(require 'whitespace)
;;(setq whitespace-style '(face empty tabs lines-tail trailing))
;;(global-whitespace-mode t)
(projectile-global-mode)
(autopair-global-mode 1)

;; Ensure tramp uses remote path
(add-to-list 'tramp-remote-path 'tramp-own-remote-path)

;; Twitter password shenanagans
(setq twittering-use-master-password t)

;; Icicles mode
(icy-mode 1)

;; Ace menu
(ace-popup-menu-mode 1)

;; Windmove
(when (fboundp 'windmove-default-keybindings)
  (windmove-default-keybindings))

;; Macro for OS checking
;; https://stackoverflow.com/questions/1817257/how-to-determine-operating-system-in-elisp
(defmacro with-system (type &rest body)
  "Evaluate BODY if `system-type' equals TYPE."
  (declare (indent defun))
  `(when (eq system-type ',type)
     ,@body))

;; Enable mouse support
(unless window-system
  (require 'mouse)
  (xterm-mouse-mode t)
  (global-set-key [mouse-4] (lambda ()
                              (interactive)
                              (scroll-down 1)))
  (global-set-key [mouse-5] (lambda ()
                              (interactive)
                              (scroll-up 1)))
  (defun track-mouse (e))
  (setq mouse-sel-mode t)
  )

;; Enable copy and paste
;;(defun copy-from-osx ()
;;  (shell-command-to-string "pbpaste"))
;;
;;(defun paste-to-osx (text &optional push)
;;  (let ((process-connection-type nil))
;;    (let ((proc (start-process "pbcopy" "*Messages*" "pbcopy")))
;;      (process-send-string proc text)
;;      (process-send-eof proc))))
;;
;;(setq interprogram-cut-function 'paste-to-osx)
;;(setq interprogram-paste-function 'copy-from-osx)
;;(xclip-mode 1)


(require 'exwm)
(require 'exwm-config)
(exwm-config-default)

(progn
 ;; Make whitespace-mode with very basic background coloring for whitespaces.
  ;; http://ergoemacs.org/emacs/whitespace-mode.html
  (setq whitespace-style (quote (face indentation spaces tabs newline space-mark tab-mark newline-mark )))

  ;; Make whitespace-mode and whitespace-newline-mode use “¶” for end of line char and “▷” for tab.
  (setq whitespace-display-mappings
        ;; all numbers are unicode codepoint in decimal. e.g. (insert-char 182 1)
        '(
          (indentation [127789])
          (newline-mark 10 [182 10]) ; LINE FEED,
          (tab-mark 9 [9655 9] [92 9]) ; tab
          )))

;; ANSI term options
(defun oleh-term-exec-hook ()
  (let* ((buff (current-buffer))
         (proc (get-buffer-process buff)))
    (set-process-sentinel
     proc
     `(lambda (process event)
        (if (string= event "finished\n")
            (kill-buffer ,buff))))))

(add-hook 'term-exec-hook 'oleh-term-exec-hook)
(eval-after-load "term"
  '(define-key term-raw-map (kbd "C-c C-y") 'term-paste))


;; Shorten yes and no
(defalias 'yes-or-no-p 'y-or-n-p)

;; Spaces, not tabs
(setq tab-width 2
      indent-tabs-mode nil)

;; Misc
(global-set-key (kbd "C-x g") 'magit-status)
(global-set-key (kbd "RET") 'newline-and-indent)

;; Indentation and cleanup
(defun untabify-buffer ()
  (interactive)
  (untabify (point-min) (point-max)))

(defun indent-buffer ()
  (interactive)
  (indent-region (point-min) (point-max)))

(defun cleanup-buffer ()
  "Perform a bunch of operations on the whitespace content of a buffer."
  (interactive)
  (indent-buffer)
  (untabify-buffer)
  (delete-trailing-whitespace))

(defun cleanup-region (beg end)
  "Remove tmux artifacts from region."
  (interactive "r")
  (dolist (re '("\\\\│\·*\n" "\W*│\·*"))
    (replace-regexp re "" nil beg end)))

(global-set-key (kbd "C-x M-t") 'cleanup-region)
(global-set-key (kbd "C-c n") 'cleanup-buffer)

;;(setq-default show-trailing-whitespace t)

;; cnc-command
(defun visible-buffers ()
  "Definition"
  (interactive)
  (mapcar '(lambda (window) (buffer-name (window-buffer window))) (window-list)))

(defun all-buffers-except-this ()
  "Definition"
  (interactive)
  (delete (buffer-name (current-buffer)) (visible-buffers))
  )

(defun cnc-from-file ()
  "A command to run commands on the other open buffers"
  (interactive)
  (dolist (elt (all-buffers-except-this))
    (comint-send-string elt (format "%s\n" (thing-at-point `line))))
  (next-line)
  t
  )

(defun cnc-prompt (cmd)
  "A command to run commands on the other open buffers"
  (interactive "sCmd: ")
  (dolist (elt (visible-buffers))
    (comint-send-string elt (format "%s\n" cmd)))
  )

(global-set-key (kbd "C-c y") `cnc-prompt)
(global-set-key (kbd "C-c C-.") `cnc-from-file)

;; Winner Mode

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; I sometimes still use C-x r w <register> to store a window configuration in a register,           ;;
;; and C-x r j <register> (where <register> is a single character) to jump back to it.               ;;
;; While this is a nice way for storing a few window configurations which you want to go             ;;
;; back to after some time, I find winner-mode to be more convenient in a few regards.               ;;
;; (For example, you won't have to bother naming the configurations).                                ;;
;; Just put (winner-mode 1) in your .emacs, bind winner-undo and winner-redo to convenient shortcuts ;;
;; (or use the IMHO awkward C-c <left> and C-c <right> predefined ones)                              ;;
;; and you'll be able to switch back to previous window configurations.                              ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(winner-mode 1)

;; Remote ansi-term
;; Use this for remote so I can specify command line arguments
(defun remote-term (new-buffer-name cmd &rest switches)
  (setq term-ansi-buffer-name (concat "*" new-buffer-name "*"))
  (setq term-ansi-buffer-name (generate-new-buffer-name term-ansi-buffer-name))
  (setq term-ansi-buffer-name (apply 'make-term term-ansi-buffer-name cmd nil switches))
  (set-buffer term-ansi-buffer-name)
  (term-mode)
  (term-char-mode)
;;  (term-set-escape-char ?\C-x)
  (switch-to-buffer term-ansi-buffer-name))

;; Use plink on windows
(with-system windows-nt
  (message "this is a windows system! I know this")
  (require 'tramp)
  (set-default 'tramp-default-method "plink"))

;; Easy window splitting
(defun split-maj-min (number)
(interactive "N")
"Function to split windows into one major window and multiple minor windows"
(split-window-horizontally)
(other-window 1)
(while (> number 1)
  (setq number (+ -1 number))
  (split-window-vertically))
(balance-windows))

(defun split-cnc (number)
(interactive "N")
"Function to split windows into one major window and multiple minor ansi-terms"
(split-window-horizontally)
(other-window 1)
(ansi-term "/bin/bash" "cnc")
(while (> number 1)
  (split-window-vertically)
  (ansi-term "/bin/bash" "cnc")
  (other-window 1)
  (setq number (+ -1 number)))
(ansi-term "/bin/bash" "cnc")
(other-window 1)
(balance-windows))

;; Move backups
(setq backup-directory-alist '(("." . "~/.emacs.d/backups")))
(setq delete-old-versions -1)
(setq version-control t)
(setq vc-make-backup-files t)
(setq auto-save-file-name-transforms '((".*" "~/.emacs.d/auto-save-list/" t)))

;; Turn of scrollbars
(scroll-bar-mode -1)

;; Dumb Jump
(global-set-key (kbd "C-c l") 'helm-projectile-switch-to-buffer)

(global-set-key (kbd "C-c <left>") 'dumb-jump-back)
(global-set-key (kbd "C-c <right>") 'dumb-jump-go)
(global-set-key (kbd "C-c <down>") 'dumb-jump-quick-look)
(global-set-key (kbd "C-2") 'helm-mini)

(setq helm-mini-default-sources 
      '(helm-source-buffers-list 
        helm-source-bookmarks 
        helm-source-recentf 
        helm-source-buffer-not-found))

(add-to-list 'load-path "/path/to/es-mode-dir")
(autoload 'es-mode "es-mode.el"
            "Major mode for editing Elasticsearch queries" t)
(add-to-list 'auto-mode-alist '("\\.es$" . es-mode))
(setq inhibit-startup-message t)

;; w3m
(setq browse-url-browser-function 'w3m-browse-url)
(autoload 'w3m-browse-url "w3m" "Ask a WWW browser to show a URL." t)
;; optional keyboard short-cut
(global-set-key "\C-xm" 'browse-url-at-point)
(setq w3m-use-cookies t)

;; Gmail
(setq user-mail-address "noonker@gmail.com"
      user-full-name "Joshua Person")


(setq gnus-select-method
      '(nnimap "outlook"
	       (nnimap-address "outlook.office365.com")  ; it could also be imap.googlemail.com if that's your server.
	       (nnimap-server-port "imaps")
	       (nnimap-stream ssl)))

(setq gnus-secondary-select-methods
      '((nnimap "gmail"
                (nnimap-address "imap.gmail.com")
                (nnimap-server-port 993)
                (nnimap-stream ssl)
                (nnimap-authinfo-file "~/.authinfo"))))

(setq smtpmail-smtp-server "smtp.gmail.com"
      smtpmail-smtp-service 587
      gnus-ignored-newsgroups "^to\\.\\|^[0-9. ]+\\( \\|$\\)\\|^[\"]\"[#'()]")

;; ipython fix
(setq python-shell-interpreter "ipython")
;;      python-shell-interpreter-args "--simple-prompt -i")

(setq tls-program
      '("gnutls-cli --insecure -p %p %h"
      "gnutls-cli --insecure -p %p %h --protocols ssl3"
      "openssl s_client -connect %h:%p -no_ssl2 -ign_eof"))

;; Google chrome as default browser
(setq browse-url-browser-function 'browse-url-chromium)

;; Temporarily maximize buffer
(defun toggle-maximize-buffer () "Maximize buffer"
  (interactive)
  (if (= 1 (length (window-list)))
    (jump-to-register '_)
    (progn
      (set-register '_ (list (current-window-configuration)))
      (delete-other-windows))))

;; Bind it to a key.
(global-set-key [(super shift return)] 'toggle-maximize-buffer)

;; Insert date
(defun insert-current-date () (interactive)
  (insert (shell-command-to-string "echo -n $(date +%Y-%m-%d)")))

;; Start hangups
(defun hangups ()
  (interactive)
  (ansi-term "hangups" "hangups"))

;; Start tmux
(defun tmux()
  (interactive)
  (ansi-term "tmux" "tmux"))

;; No menus by default
(tool-bar-mode -1)
(menu-bar-mode -1)

;; load theme
(load-theme 'monokai t)
