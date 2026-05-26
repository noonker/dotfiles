# Bash initialization for interactive non-login shells and
# for remote shells (info "(bash) Bash Startup Files").

# Export 'SHELL' to child processes.  Programs such as 'screen'
# honor it and otherwise use /bin/sh.
export SHELL

# Guix exports SSL_CERT_FILE/CURL_CA_BUNDLE/etc. pointing into the store
# (via nss-certs search paths). Inside a distrobox/toolbox /gnu/store isn't
# mounted, so that path dangles and TLS (pip, curl, git) breaks. When the
# Guix bundle is unreachable, fall back to the container's own bundle.
# No-op on the host, where the path resolves.
if [ -n "$SSL_CERT_FILE" ] && [ ! -e "$SSL_CERT_FILE" ]; then
    for _b in /etc/ssl/certs/ca-certificates.crt /etc/pki/tls/certs/ca-bundle.crt; do
        if [ -e "$_b" ]; then
            export SSL_CERT_FILE="$_b" CURL_CA_BUNDLE="$_b" \
                   GIT_SSL_CAINFO="$_b" REQUESTS_CA_BUNDLE="$_b"
            export SSL_CERT_DIR=/etc/ssl/certs
            break
        fi
    done
    unset _b
fi

if [[ $- != *i* ]]
then
    # We are being invoked from a non-interactive shell.  If this
    # is an SSH session (as in "ssh host command"), source
    # /etc/profile so we get PATH and other essential variables.
    [[ -n "$SSH_CLIENT" ]] && source /etc/profile

    # Don't do anything else.
    return
fi

# Source the system-wide file.
# source /etc/bashrc

PATH="$PATH:$HOME/.local/share/yabridge"
PATH="$PATH:$HOME/.local/bin"
PATH="$PATH:$HOME/bin"
PATH="$HOME/clojure/bin:$PATH"

export JAVA_HOME=$HOME/jdk24
PATH=$JAVA_HOME/bin:$PATH
export PATH

# Python
# source $HOME/.virtualenvs/system/bin/activate

# Adjust the prompt depending on whether we're in 'guix environment'.
if [ -n "$GUIX_ENVIRONMENT" ]
then
    PS1='\u@\h \w [env]\$ '
else
    PS1='\u@\h \w\$ '
fi
alias ls='ls -p --color=auto'
alias ll='ls -l'
alias grep='grep --color=auto'
