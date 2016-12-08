$programs=
  ("1password", "https://agilebits.com/downloads"),
  ("7zip", "http://www.7-zip.org/download.html"),
  ("Ableton", "https://www.ableton.com/en/account/"),
  ("Affinity", "https://affinity.store/en-us/sign-in/"),
  ("Audacity", "http://old.audacityteam.org/download/"),
  ("Battle.net", "https://us.battle.net/download/en/"),
  ("Roland Drivers", "https://www.roland.com/global/support/by_product/duo-capture_ex/updates_drivers/"),
  ("F.lux", "https://justgetflux.com/"),
  ("GnuRadio", "http://www.gcndevelopment.com/gnuradio/downloads.htm"),
  ("QT", "https://www.qt.io/download/"),
  ("Chrome", "https://www.qt.io/download/"),
  ("VS Code", "https://code.visualstudio.com"),
  ("VS IDE", "https://www.visualstudio.com/vs/"),
  ("Firefox", "https://www.mozilla.org/en-US/firefox/products/"),
  ("Native Instruments", "https://www.native-instruments.com/en/login/?redirect=%2Fen%2Fmy-account%2F"),
  ("qBittorrent", "http://www.qbittorrent.org/download.php"),
  ("Keith McMillen", "https://www.keithmcmillen.com/downloads/"),
  ("SharkpKeys", "http://sharpkeys.codeplex.com/"),
  ("Steam", "http://store.steampowered.com/about/"),
  ("Synergy", "https://symless.com/account/"),
  ("VLC", "http://www.videolan.org/vlc/index.html"),
  ("Wireshark", "https://www.wireshark.org/#download"),
  ("xming", "https://sourceforge.net/projects/xming/"),
  ("Anaconda", "https://www.continuum.io/downloads")

ForEach ($item in $programs) {
  Start-Process $item[1]
}

