;; bliss and its Emacs front end, pinned to commits on GitHub.
;; Guix also has an unrelated `bliss'; refer to these by variable.

(define-module (noonker packages bliss)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix build-system emacs)
  #:use-module (guix build-system pyproject)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages emacs-xyz)    ; emacs-transient
  #:use-module (gnu packages python-build) ; python-setuptools
  #:export (bliss emacs-bliss))

(define bliss
  (let ((commit "90991fb2ee6ddcab484d3efd2fbb4784d89b47dc")
        (revision "0"))
    (package
      (name "bliss")
      (version (git-version "0.1.0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/noonker/bliss")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "17ih7mlsl19yz4vpslhyvwa524nwgb8rnrb2wwgbc6jhidik76q1"))))
      (build-system pyproject-build-system)
      (arguments
       (list #:test-flags #~(list "-m" "unittest" "discover" "tests")
             #:phases
             #~(modify-phases %standard-phases
                 (replace 'check
                   (lambda* (#:key tests? test-flags #:allow-other-keys)
                     (when tests?
                       (apply invoke "python3" test-flags)))))))
      (native-inputs (list python-setuptools))
      (home-page "https://github.com/noonker/bliss")
      (synopsis "Send a directory, env and Guix/Nix shell to another machine")
      (description
       "bliss moves the current directory, environment and shell closure to a
podman or docker container, a tmux or screen session on a remote Linux server,
or a Kubernetes pod or deployment, with a normal or an AI entrypoint.")
      (license license:gpl3+))))

(define emacs-bliss
  (let ((commit "af807fc59c2d25fed5dbd865f08b5a9c7ca661b1")
        (revision "0"))
    (package
      (name "emacs-bliss")
      (version (git-version "0.1.0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/noonker/emacs-bliss")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "1ks4zsp3c4ba49f9c7qb1vpxcr4mrc5y3r5z57ncvkk7dgx61dfi"))))
      (build-system emacs-build-system)
      (arguments
       (list #:test-command
             #~(list "emacs" "-Q" "--batch" "-L" "." "-L" "test"
                     "-l" "test/bliss-test.el" "-f" "ert-run-tests-batch-and-exit")))
      (propagated-inputs (list emacs-transient))
      (home-page "https://github.com/noonker/emacs-bliss")
      (synopsis "Emacs front end for bliss")
      (description
       "List bliss workloads with their live state, attach to them, read their
logs, and start commands or AI agents on any bliss target from Emacs.")
      (license license:gpl3+))))
