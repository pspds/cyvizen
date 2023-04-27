{ lib, pkgs, ... }:
with pkgs;
[
  age
  cached-nix-shell
  clinfo
  gsound
  libsecret
  libva-utils
  niv
  nodejs
  rsync
  signify
  sops
  trashy # replacement for rm -rf
  vdpauinfo
  vulkan-tools
  bpytop
  micro
  nix-search-cli
]
