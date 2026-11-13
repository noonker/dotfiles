pull:
	guix pull
laptop:
	sudo -E $$(command -v guix) system reconfigure -L ${HOME}/git/dotfiles/guix/channels ${HOME}/git/dotfiles/guix/channels/noonker/system/personal-laptop.scm
home:
	guix home reconfigure -L ${HOME}/git/dotfiles/guix/channels -L ${HOME}/git/norns-guix ${HOME}/git/dotfiles/guix/home-configuration.scm
iso:
	guix system image -t iso9660 -L ${HOME}/git/dotfiles/guix/channels ${HOME}/git/dotfiles/guix/channels/noonker/system/personal-laptop.scm
