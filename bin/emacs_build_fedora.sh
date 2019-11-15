sudo dnf install libxml2-devel libX11-devel gtk3-devel libXpm-devel libjpeg-devel gnutls-devel giflib-devel
sudo dnf groupinstall "Development Tools" "Development Libraries"
./configure --prefix=/home/user/emacs --bindir=/home/user/bin --with-x-toolkit=gtk3 --with-modules --with-dbus --with-gif --with-jpeg --with-png --with-rsvg --with-tiff --with-xft --with-xpm --with-gpm=no
make
make install
