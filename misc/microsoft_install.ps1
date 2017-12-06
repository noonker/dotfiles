$programs=
  ("7zip", "http://www.7-zip.org/download.html"),
  ("Ableton", "https://www.ableton.com/en/account/"),
  ("Native Instruments", "https://www.native-instruments.com/en/login/?redirect=%2Fen%2Fmy-account%2F"),
  ("qBittorrent", "http://www.qbittorrent.org/download.php"),
  ("Keith McMillen", "https://www.keithmcmillen.com/downloads/"),
  ("VLC", "http://www.videolan.org/vlc/index.html"),
  ("Wireshark", "https://www.wireshark.org/#download"),
  ("Firefox", "https://www.mozilla.org/en-US/firefox/developer/"),
  ("Emacs", "https://www.gnu.org/software/emacs/"),
  ("Audacity", "http://www.audacityteam.org/"),
  ("Clip Studio", "http://www.clipstudio.net/en"),
  ("Virtualbox", "https://www.virtualbox.org/wiki/Downloads"),
  ("Tascam", "http://tascam.com/product/us-2x2/downloads/"),
  ("Kindle", "https://www.amazon.com/kindlepcdownload/")

ForEach ($item in $programs) {
  Start-Process $item[1]
}

