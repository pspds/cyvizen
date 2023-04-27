{ lib, pkgs, ... }:
with pkgs;
[
  bat
  broot
  micro
  ncdu
  niv
  zstd
  pciutils
  dmidecode

  gnupg
  which
  coreutils
  gnutar
  gzip
  cached-nix-shell
  nodejs
  nodePackages.pnpm
]
