;;; Emacs packages Guix doesn't carry, plus forks of ones it does.  Pinned from
;;; the commits straight.el was using when these were migrated off it.

(define-module (noonker packages emacs)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix build-system emacs)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (gnu packages emacs-build)
  #:use-module (gnu packages emacs-xyz))

(define-public emacs-agent-shell-monome
  (let ((commit "e5539031db55568522f0c11391f71bd69e0f88db")
        (revision "0"))
    (package
      (name "emacs-agent-shell-monome")
      (version (git-version "0.2.0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/noonker/agent-shell-monome")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "0jxj1dk98cbxp5pc61j17ljkx97gn5zpccb52zzj0qrc0vcxh2pa"))))
      (build-system emacs-build-system)
      (propagated-inputs
       (list emacs-agent-shell))
      (home-page "https://github.com/noonker/agent-shell-monome")
      (synopsis "Show agent-shell activity on a monome grid")
      (description "Show agent-shell activity on a monome grid.")
      (license license:gpl3+))))

(define-public emacs-agent-shell-org-loops
  (let ((commit "892d6a6d1f86694039a3735be99045ffe1f85e92")
        (revision "0"))
    (package
      (name "emacs-agent-shell-org-loops")
      (version (git-version "0.1.0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/noonker/agent-shell-org-loops")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "0rb11npparqihsgpmmn7r9c46flnks4mmqlcw0j07jnl1vpvlp6p"))))
      (build-system emacs-build-system)
      (arguments
       (list #:test-command
             #~(list "emacs" "-Q" "--batch" "-L" "." "-L" "test"
                     "-l" "test/agent-shell-org-loops-test.el"
                     "-f" "ert-run-tests-batch-and-exit")))
      (propagated-inputs
       (list emacs-agent-shell))
      (home-page "https://github.com/noonker/agent-shell-org-loops")
      (synopsis "Drive agent-shell loops from Org")
      (description "Drive agent-shell loops from Org.")
      (license #f))))

(define-public emacs-consult-ag
  (let ((commit "7fc4b36613d4f6d06d28999c1a03b3218ee1529b")
        (revision "0"))
    (package
      (name "emacs-consult-ag")
      (version (git-version "0.2.0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/yadex205/consult-ag")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "0dgw7g682sf38f7649xk9jri0sri9xin25xz53yxac3iahij0a7j"))))
      (build-system emacs-build-system)
      (propagated-inputs
       (list emacs-consult))
      (home-page "https://github.com/yadex205/consult-ag")
      (synopsis "Consult integration for ag")
      (description "Consult integration for ag.")
      (license license:expat))))

(define-public emacs-d2-mode
  (let ((commit "e1fc7d6c1915acaf476060c0f79b8bdef6bd1952")
        (revision "0"))
    (package
      (name "emacs-d2-mode")
      (version (git-version "1.0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/andorsk/d2-mode")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "101y3mrc652sdfglnrrg8yhgz5y3xnl4wlk9jzplr97nk8af0s79"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/andorsk/d2-mode")
      (synopsis "Major mode for the D2 diagram language")
      (description "Major mode for the D2 diagram language.")
      (license license:gpl3+))))

(define-public emacs-el-easydraw
  (let ((commit "6a68a77b5d837e83280c927ecda9844190eeb3e6")
        (revision "0"))
    (package
      (name "emacs-el-easydraw")
      (version (git-version "0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/misohena/el-easydraw")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "1hyrzyazi5afabmd91yg4mq3d6l35psjdv4bz0a2z4gy8w9yib3m"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/misohena/el-easydraw")
      (synopsis "Embedded drawing tool for Org")
      (description "Embedded drawing tool for Org.")
      (license license:gpl3+))))

(define-public emacs-playlist
  (let ((commit "ba679e75e765753854d9624f30cb6d7286af39d2")
        (revision "0"))
    (package
      (name "emacs-playlist")
      (version (git-version "0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/noonker/emacs-playlist")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "1lszvz9ibwg5bkavv9kgf9a9cpawlk14gj94q5ad6jyy5znb9cvs"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/noonker/emacs-playlist")
      (synopsis "Playlist helper for Emacs")
      (description "Playlist helper for Emacs.")
      (license #f))))

(define-public emacs-erc-colorize
  (let ((commit "998a37e950dc2ad026bdd192b37889f65d4e858e")
        (revision "0"))
    (package
      (name "emacs-erc-colorize")
      (version (git-version "0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/thisirs/erc-colorize")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "0aflxlq5gispm1zvdvbybwv4cnn42ac8dl8zc96fsly30g384ia4"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/thisirs/erc-colorize")
      (synopsis "Colorize ERC messages per nickname")
      (description "Colorize ERC messages per nickname.")
      (license license:gpl3+))))

(define-public emacs-json-to-org-table
  (let ((commit "d1e2bf0d51a14ecb462445488e46878ae335ef42")
        (revision "0"))
    (package
      (name "emacs-json-to-org-table")
      (version (git-version "0.0.1" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/noonker/json-to-org-table")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "031c8qd7h93hvchrp4yn18y3h4zfcqlqpcqzz6r1cbcam3wfpj62"))))
      (build-system emacs-build-system)
      (arguments
       (list
        #:phases
        #~(modify-phases %standard-phases
            ;; The unquoted version in Package-Requires can't be parsed.
            (add-after 'unpack 'fix-package-requires
              (lambda _
                (substitute* "json-to-org-table.el"
                  (("\\(\\(emacs 27\\.1\\)\\)") "((emacs \"27.1\"))")))))))
      (home-page "https://github.com/noonker/json-to-org-table")
      (synopsis "Convert JSON to Org tables")
      (description "Convert JSON to Org tables.")
      (license #f))))

(define-public emacs-kubel
  (let ((commit "58d4d3c0f0a3188903831ac11489b6b2da2b8f34")
        (revision "0"))
    (package
      (name "emacs-kubel")
      (version (git-version "1.0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/noonker/kubel")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "1yafyqmf11ncm8j9zjn3d48d7ck6217dfxzqyrw6y3b6i75sj33v"))))
      (build-system emacs-build-system)
      (propagated-inputs
       (list emacs-dash
             emacs-evil
             emacs-s
             emacs-transient
             emacs-yaml-mode))
      (home-page "https://github.com/noonker/kubel")
      (synopsis "Kubernetes porcelain for Emacs (fork with extra porcelains)")
      (description "Kubernetes porcelain for Emacs (fork with extra porcelains).")
      (license license:gpl2+))))

(define-public emacs-mermaid-mode
  (let ((commit "804dbcb1452e7496ae0c48e20362da6351227246")
        (revision "0"))
    (package
      (name "emacs-mermaid-mode")
      (version (git-version "1.0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/abrochard/mermaid-mode")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "1f1dzabb5647la40siwifv90678xpig2bsn5dl1p1s88q5xs9yk9"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/abrochard/mermaid-mode")
      (synopsis "Major mode for Mermaid diagrams")
      (description "Major mode for Mermaid diagrams.")
      (license license:gpl3+))))

(define-public emacs-norns
  (let ((commit "d08eed8555a619a13aa99cfa2ef40e199e86114c")
        (revision "0"))
    (package
      (name "emacs-norns")
      (version (git-version "0.0.3" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/p3r7/norns.el")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "104ds1h8pi3qdjqq1d8gsgkajq29025hg7hgs9lrg63dw591b66z"))))
      (build-system emacs-build-system)
      ;; Upstream's `make check' needs tools that aren't in the build.  It also
      ;; can't be byte-compiled: a macro uses a defconst from the same file at
      ;; expansion time.  It runs fine as source.
      (arguments
       (list
        #:tests? #f
        #:phases
        #~(modify-phases %standard-phases
            (delete 'build))))
      (propagated-inputs
       (list emacs-dash
             emacs-f
             emacs-lua-mode
             emacs-request
             emacs-s
             emacs-websocket))
      (home-page "https://github.com/p3r7/norns.el")
      (synopsis "Interact with monome norns from Emacs")
      (description "Interact with monome norns from Emacs.")
      (license license:expat))))

(define-public emacs-ob-agent-shell
  (let ((commit "494608c80da381de93f0f9ef1fcabbf8aa371343")
        (revision "0"))
    (package
      (name "emacs-ob-agent-shell")
      (version (git-version "0.3.0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/eddof13/ob-agent-shell")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "11hjkc8gr5hlprmsxr5pkiq5x4knh7q21qyxznbj3s5s38h9gd64"))))
      (build-system emacs-build-system)
      (propagated-inputs
       (list emacs-agent-shell))
      (home-page "https://github.com/eddof13/ob-agent-shell")
      (synopsis "Org Babel support for agent-shell")
      (description "Org Babel support for agent-shell.")
      (license license:gpl3+))))

(define-public emacs-ob-d2
  (let ((commit "5d197f8225a9fb4da997235b231abe30049c6825")
        (revision "0"))
    (package
      (name "emacs-ob-d2")
      (version (git-version "0.0.3" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/xcapaldi/ob-d2")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "00iv5zj4zi6h8c8jgs8hxh2cp2nfm3aavjjizd322nmrn6yxf160"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/xcapaldi/ob-d2")
      (synopsis "Org Babel support for D2")
      (description "Org Babel support for D2.")
      (license license:gpl3+))))

(define-public emacs-ob-markdown
  (let ((commit "c1dd225d468c73c2bd7489c2de79a956c051b519")
        (revision "0"))
    (package
      (name "emacs-ob-markdown")
      (version (git-version "0.01" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/emacsmirror/ob-markdown")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "0qm53zxwss882zgwf51898p78rab9pblkz1ibr3fljs9sdwrpbrw"))))
      (build-system emacs-build-system)
      (propagated-inputs
       (list emacs-markdown-mode))
      (home-page "https://github.com/emacsmirror/ob-markdown")
      (synopsis "Org Babel support for Markdown")
      (description "Org Babel support for Markdown.")
      (license license:gpl3+))))

(define-public emacs-ob-mermaid
  (let ((commit "30c2da02e3d24dbec0d004d3c6dfe7b381500b05")
        (revision "0"))
    (package
      (name "emacs-ob-mermaid")
      (version (git-version "0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/arnm/ob-mermaid")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "09mhzj1x4zvfj9yik71rcnk02rlidq2si018ah9iwy93r49hdslv"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/arnm/ob-mermaid")
      (synopsis "Org Babel support for Mermaid")
      (description "Org Babel support for Mermaid.")
      (license license:gpl3+))))

(define-public emacs-ob-sql-mode
  (let ((commit "2eaf436a6ac2178b94442d80f84fc6c02aa644d8")
        (revision "0"))
    (package
      (name "emacs-ob-sql-mode")
      (version (git-version "1.1" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/nikclayton/ob-sql-mode")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "0w1d3a09x8fq09qr8r7h5794nwlnjg19rxhgaysnglbik6r3072q"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/nikclayton/ob-sql-mode")
      (synopsis "Org Babel support using sql-mode")
      (description "Org Babel support using sql-mode.")
      (license license:gpl3+))))

(define-public emacs-ob-typescript
  (let ((commit "5fe1762f8d8692dd5b6f1697bedbbf4cae9ef036")
        (revision "0"))
    (package
      (name "emacs-ob-typescript")
      (version (git-version "0.1" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/lurdan/ob-typescript")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "1zgnls92pyy950xcly5y7jkr72xcpxq94lqa39gbhad93b7bfffc"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/lurdan/ob-typescript")
      (synopsis "Org Babel support for TypeScript")
      (description "Org Babel support for TypeScript.")
      (license license:gpl3+))))

(define-public emacs-somafm
  (let ((commit "48a561e07a9e114e38eae2222d94c392c3d63dcc")
        (revision "0"))
    (package
      (name "emacs-somafm")
      (version (git-version "0.1.0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/artenator/somafm.el")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "0vsmxqiy05zpn6ivq811d8y7cxjyzj3gmqivhkw0pl1m2zwg0zfd"))))
      (build-system emacs-build-system)
      (propagated-inputs
       (list emacs-dash
             emacs-request))
      (home-page "https://github.com/artenator/somafm.el")
      (synopsis "SomaFM client for Emacs")
      (description "SomaFM client for Emacs.")
      (license license:gpl3+))))

(define-public emacs-tidal
  (let ((commit "5ae655255d87c983a596f398a0385b21df97df3b")
        (revision "0"))
    (package
      (name "emacs-tidal")
      (version (git-version "0.0.1" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://codeberg.org/uzu/tidal")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "0c51zyqbyly8h7zwxnxc9sbfx3md170y0ckpvrsmycq0kwgs0mm0"))))
      (build-system emacs-build-system)
      (propagated-inputs
       (list emacs-haskell-mode))
      (home-page "https://codeberg.org/uzu/tidal")
      (synopsis "Major mode for TidalCycles")
      (description "Major mode for TidalCycles.")
      (license license:gpl3+))))

(define-public emacs-verb
  (let ((commit "ef09a5804cac4816ca9a0d1fb9c71c8ed3d3df8f")
        (revision "0"))
    (package
      (name "emacs-verb")
      (version (git-version "3.2.0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/federicotdn/verb")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "0cli080ndalc7xc96f017xk6b5b00hfz0831r64jx8ci9xscwr5a"))))
      (build-system emacs-build-system)
      ;; Upstream's `make check' needs tools that aren't in the build.
      (arguments (list #:tests? #f))
      (home-page "https://github.com/federicotdn/verb")
      (synopsis "HTTP client for Org")
      (description "HTTP client for Org.")
      (license license:gpl3+))))

(define-public emacs-yara-mode
  (let ((commit "2b097f685e2770d2c16e5f59e1434a8dcc38db86")
        (revision "0"))
    (package
      (name "emacs-yara-mode")
      (version (git-version "0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/binjo/yara-mode")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "1l1v1nnl93gmj1gg5h254v1v0c417pywblifqyggkjn66jppwgwf"))))
      (build-system emacs-build-system)
      (home-page "https://github.com/binjo/yara-mode")
      (synopsis "Major mode for YARA rules")
      (description "Major mode for YARA rules.")
      (license license:gpl2+))))

(define-public %my-emacs-packages
  (list emacs-agent-shell-monome
        emacs-agent-shell-org-loops
        emacs-consult-ag
        emacs-d2-mode
        emacs-el-easydraw
        emacs-erc-colorize
        emacs-json-to-org-table
        emacs-kubel
        emacs-mermaid-mode
        emacs-norns
        emacs-ob-agent-shell
        emacs-ob-d2
        emacs-ob-markdown
        emacs-ob-mermaid
        emacs-ob-sql-mode
        emacs-ob-typescript
        emacs-playlist
        emacs-somafm
        emacs-tidal
        emacs-verb
        emacs-yara-mode))
