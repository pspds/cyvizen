args@{ lib
, userName ? null
, ...
}:
let
  pkgs = import ../nix (args // { inherit userName; });
  chain = args // {
    inherit pkgs;
    inherit userName;
  };
in
with pkgs;
[
  # https://github.com/yang991178/fluent-reader
  # https://itsfoss.com/cad-software-linux/
  # https://itsfoss.com/koodo-ebook-reader/
  # minder?
  # persepolis
  age
  appimage-run
  audacity
  bibletime
  blanket
  blender
  bpytop
  cached-nix-shell
  clevis
  clinfo
  copyq
  croc
  cryptsetup
  curtail
  dialect
  dmidecode
  evolution
  filezilla
  flowblade
  font-manager
  freecad
  gaphor
  gimp
  gnome-firmware
  godot
  gpick
  gsound
  gthumb
  handbrake
  hunspell
  inkscape-with-extensions
  jitsi-meet-electron
  keepassxc
  librecad
  libreoffice
  libsecret
  libva-utils
  mat2 # metadata-cleaner cli
  metadata-cleaner
  micro
  nix-diff
  nix-tree
  nixpkgs-fmt
  nodejs
  opensnitch-ui
  pencil
  pidgin
  pinta
  ptask
  qalculate-gtk
  qgis
  rawtherapee
  rclone
  remmina
  ripgrep-all
  rsync
  scribus
  signify
  sops
  soundconverter
  sticky
  taskwarrior
  trashy # replacement for rm -rf
  ungoogled-chromium
  vdpauinfo
  vulkan-tools
  vulnix
  xfce.mousepad
  xfce.parole
  yacreader
]
++ callPackage ./sets/self.nix chain
++ callPackage ./sets/gnome.nix chain
++ callPackage ./sets/gnomeExtensions.nix chain
++ (if userName == null then [ ] else callPackage (./. + "/../cyvizens/${userName}/nix/pkgs") chain)
