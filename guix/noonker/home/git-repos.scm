(define-module (noonker home git-repos)
  #:use-module (gnu home services)
  #:use-module (gnu services configuration)
  #:use-module (guix gexp)
  #:use-module (guix records)
  #:export (home-git-repos-service-type
            home-git-repos-configuration))

(define-record-type* <home-git-repos-configuration>
  home-git-repos-configuration make-home-git-repos-configuration
  home-git-repos-configuration?
  (repos home-git-repos-configuration-repos ;; alist of (name . url)
         (default '()))
  (directory home-git-repos-configuration-directory
             (default "~/git")))

(define (home-git-repos-activation config)
  (let ((repos (home-git-repos-configuration-repos config))
        (dir   (home-git-repos-configuration-directory config)))
    #~(begin
        (use-modules (guix build utils))
        (let ((git #$(file-append (@ (gnu packages version-control) git)
                                  "/bin/git"))
              (base-dir (string-append (getenv "HOME")
                                       #$(string-drop dir 1)))) ;; drop ~
          (mkdir-p base-dir)
          (for-each
           (lambda (repo)
             (let* ((name (car repo))
                    (url  (cdr repo))
                    (dest (string-append base-dir "/" name)))
               (if (file-exists? dest)
                   (begin
                     (format #t "Pulling ~a...~%" name)
                     (system* git "-C" dest "pull" "--ff-only"))
                   (begin
                     (format #t "Cloning ~a...~%" name)
                     (system* git "clone" url dest)))))
           '#$repos)))))

(define home-git-repos-service-type
  (service-type
   (name 'home-git-repos)
   (extensions
    (list (service-extension home-activation-service-type
                             home-git-repos-activation)))
   (description "Clone or pull git repos on home reconfigure.")
   (default-value (home-git-repos-configuration))))
