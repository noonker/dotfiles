$programs=
  ("7zip", "http://www.7-zip.org/download.html"),
  ("Ableton", "https://www.ableton.com/en/account/"),
  ("GnuRadio", "http://www.gcndevelopment.com/gnuradio/downloads.htm"),
  ("QT", "https://www.qt.io/download/"),
  ("Native Instruments", "https://www.native-instruments.com/en/login/?redirect=%2Fen%2Fmy-account%2F"),
  ("qBittorrent", "http://www.qbittorrent.org/download.php"),
  ("Keith McMillen", "https://www.keithmcmillen.com/downloads/"),
  ("VLC", "http://www.videolan.org/vlc/index.html"),
  ("Wireshark", "https://www.wireshark.org/#download"),
  ("xming", "https://sourceforge.net/projects/xming/"),
  ("Anaconda", "https://www.continuum.io/downloads"),
  ("Firefox", "https://www.mozilla.org/en-US/firefox/developer/"),
  ("Emacs", "https://www.gnu.org/software/emacs/"),
  ("Msys2", "http://www.msys2.org/"),
  ("Kindle", "https://www.amazon.com/kindlepcdownload/")

ForEach ($item in $programs) {
  Start-Process $item[1]
}

