HOME_ENVIRONMENT=$HOME/.guix-home
. $HOME_ENVIRONMENT/setup-environment
$HOME_ENVIRONMENT/on-first-login
unset HOME_ENVIRONMENT

PATH="$PATH:$HOME/.local/share/yabridge"
PATH="$PATH:$HOME/.local/bin"
PATH="$PATH:$HOME/bin"
PATH="$HOME/clojure/bin:$PATH"
export JAVA_HOME=$HOME/jdk24
PATH=$JAVA_HOME/bin:$PATH
export PATH
