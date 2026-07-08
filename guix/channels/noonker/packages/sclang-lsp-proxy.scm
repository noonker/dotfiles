(define-module (noonker packages sclang-lsp-proxy)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix build-system trivial)
  #:use-module (gnu packages python))

(define-public sclang-lsp-proxy
  (package
    (name "sclang-lsp-proxy")
    (version "0.1.0")
    (source (local-file "sclang-lsp-proxy.py"))
    (build-system trivial-build-system)
    (arguments
     (list
      #:modules '((guix build utils))
      #:builder
      (with-imported-modules '((guix build utils))
        #~(begin
            (use-modules (guix build utils))
            (let* ((bin (string-append #$output "/bin"))
                   (dest (string-append bin "/sclang-lsp-proxy")))
              (mkdir-p bin)
              (copy-file #$(local-file "sclang-lsp-proxy.py") dest)
              (substitute* dest
                (("^#!/usr/bin/env python3")
                 (string-append "#!" #$(file-append python "/bin/python3"))))
              (chmod dest #o755))))))
    (inputs (list python))
    (home-page "https://github.com/scztt/vscode-supercollider")
    (synopsis "UDP<->stdio proxy for the SuperCollider language server")
    (description
     "Shim that spawns @command{sclang} with @code{LanguageServer.quark}
enabled and exposes its UDP-based LSP transport as ordinary stdio, so
generic LSP clients (Emacs eglot, lsp-mode, etc.) can talk to it.

Requires the language server quark to be installed on the sclang side:
@code{Quarks.install(\"https://github.com/scztt/LanguageServer.quark\");}")
    (license license:gpl3+)))

sclang-lsp-proxy
