;; -*- lexical-binding: t -*-

;; Packages come from Guix.  Left on, package.el would put anything in
;; ~/.emacs.d/elpa ahead of them.
(setq package-enable-at-startup nil)

;; The daemon keeps the environment from when the session started, so it can
;; miss TREE_SITTER_GRAMMAR_PATH.  Name the profiles directly.
(setq treesit-extra-load-path
      (list (expand-file-name "~/.guix-home/profile/lib/tree-sitter")
            (expand-file-name "~/.guix-profile/lib/tree-sitter")))

;; Files outside this config (scel, Guix's copyright.el) have no cookie.
(setq warning-suppress-types '((files missing-lexbind-cookie))
      warning-suppress-log-types '((files missing-lexbind-cookie)))

;; Guix's emacs-org sets off its own version check even in a shell holding only
;; Emacs and that package, with one Org on the load-path.
(define-advice display-warning (:before-until (_type message &rest _) hide-org-mismatch)
  (and (stringp message)
       (string-prefix-p "Org version mismatch" message)))
