$programs=
  ("7zip", "http://www.7-zip.org/download.html"),
  ("Ableton", "https://www.ableton.com/en/account/"),
  ("Native Instruments", "https://www.native-instruments.com/en/login/?redirect=%2Fen%2Fmy-account%2F"),
  ("qBittorrent", "http://www.qbittorrent.org/download.php"),
  ("Keith McMillen", "https://www.keithmcmillen.com/downloads/"),
  ("VLC", "http://www.videolan.org/vlc/index.html"),
  ("Wireshark", "https://www.wireshark.org/#download"),
  ("Firefox", "https://www.mozilla.org/en-US/firefox/developer/"),
  ("Audacity", "http://www.audacityteam.org/"),
  ("Clip Studio", "http://www.clipstudio.net/en"),
  ("Virtualbox", "https://www.virtualbox.org/wiki/Downloads"),
  ("Tascam", "http://tascam.com/product/us-2x2/downloads/"),
  ("Kindle", "https://www.amazon.com/kindlepcdownload/"),
  ("Gimp", "https://www.gimp.org/downloads/"),
  ("ASIO4ALL", "http://www.asio4all.org/"),
  ("Splice", "https://splice.com/"),
  ("Renoise", "https://backstage.renoise.com"),
  ("Gimp", "https://www.gimp.org/"),
  ("Blender", "https://www.blender.org/download/")

ForEach ($item in $programs) {
  Start-Process $item[1]
}


@powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))" && SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin

cinst Gow
cinst git.install
cinst poshgit
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

cinst Git-Credential-Manager-for-Windows
cinst github
cinst python
cinst pip
cinst easy.install
cinst docker-for-windows
cinst emacs
setx HOME %USERPROFILE%
setx PATH "%PATH%;%USERPROFILE%\bin"
cinst Gpg4win
cinst ag
cinst miktex 
