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

;; Assuming you wish to install "iedit" and "magit"
(ensure-package-installed 'iedit
                          'magit
                          'flycheck
                          'helm
                          'powerline
                          'evil
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
			  'restclient)

(evil-mode t)
(global-flycheck-mode)
(global-linum-mode t)
(powerline-default-theme)
(global-company-mode)

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

(require 'whitespace)
(setq whitespace-style '(face empty tabs lines-tail trailing))
(global-whitespace-mode t)
(projectile-global-mode)
(autopair-global-mode 1)


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

(setq-default show-trailing-whitespace t)

;; Move backups
(setq backup-directory-alist '(("." . "~/.emacs.d/backups")))
(setq delete-old-versions -1)
(setq version-control t)
(setq vc-make-backup-files t)
(setq auto-save-file-name-transforms '((".*" "~/.emacs.d/auto-save-list/" t)))

(global-set-key (kbd "C-c l") 'helm-projectile-switch-to-buffer)

(global-set-key (kbd "C-c <left>") 'dumb-jump-back)
(global-set-key (kbd "C-c <right>") 'dumb-jump-go)
(global-set-key (kbd "C-c <down>") 'dumb-jump-quick-look)

(add-to-list 'load-path "/path/to/es-mode-dir")
(autoload 'es-mode "es-mode.el"
            "Major mode for editing Elasticsearch queries" t)
(add-to-list 'auto-mode-alist '("\\.es$" . es-mode))
(setq inhibit-startup-message t)

(setq tls-program
      '("gnutls-cli --insecure -p %p %h"
      "gnutls-cli --insecure -p %p %h --protocols ssl3"
      "openssl s_client -connect %h:%p -no_ssl2 -ign_eof"))
