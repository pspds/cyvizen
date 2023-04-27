{ pkgs, ... }:
let
  sources = import /cyvizen/nixos/nix/sources.nix;
in
{
  allowUnfree = builtins.pathExists (/cyvizen/nixos/nix/allowUnfree);
  packageOverrides = pkgs: {
    xsaneGimp = pkgs.xsane.override { gimpSupport = true; };
    nur = import sources.NUR { inherit pkgs; };
  };
}
