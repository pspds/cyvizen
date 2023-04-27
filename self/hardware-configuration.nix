# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:
let
  hostID = "00000000";
in
{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  # defaults for closure compilation
  # NOT used in deployed system, entire file overwritten by nixos-generate-config
  fileSystems."/" =
    {
      device = "none";
      fsType = "tmpfs";
    };

  swapDevices = [ ];
  # automatically generated file, default included in repo for closure validation
  networking = {
    hostName = "cyvizen-${hostID}";
    hostId = "${hostID}";
  };
}