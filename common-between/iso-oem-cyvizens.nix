{ lib, config, pkgs, ... }:
let
  allowUnfree = builtins.pathExists (/cyvizen/nixos/nix/allowUnfree);
  supportedFilesystems = [ "vfat" "tmpfs" "btrfs" ];
in
with lib;
{
  boot = {
    initrd.supportedFilesystems = supportedFilesystems;
    loader.grub.memtest86.enable = allowUnfree;
    supportedFilesystems = supportedFilesystems;
    tmpOnTmpfs = true;
    tmpOnTmpfsSize = "80%";
  };

  environment.shells = [ pkgs.bashInteractive ];

  hardware = {
    bluetooth = {
      enable = mkDefault true;
      package = mkDefault pkgs.bluezFull;
      powerOnBoot = mkDefault true;
    };
    cpu.intel.updateMicrocode = true;
    # NOTE describes non-discoverable hardware, for debugging and easier support or porting to alternative hardware
    deviceTree.enable = true;
    enableRedistributableFirmware = true;
    enableAllFirmware = mkDefault allowUnfree;
    i2c.enable = true;
    ksm.enable = true;
    mcelog.enable = true;
    # NOTE Assume Intel Graphics as typically expected in UltraBooks
    opengl.extraPackages = with pkgs; [
      intel-compute-runtime # OpenCL
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      vaapiIntel # LIBVA_DRIVER_NAME=i965
      vaapiVdpau
      libvdpau-va-gl
    ];
    pulseaudio = {
      enable = true;
      package = pkgs.pulseaudioFull;
    };
    rasdaemon.enable = true;
    sane = {
      enable = true;
      extraBackends = [ pkgs.sane-airscan ];
      openFirewall = true;
    };
  };
  sound.enable = true;

  nix.settings.experimental-features = "nix-command flakes";
  nixpkgs.config.allowUnfree = allowUnfree;

  nixpkgs.hostPlatform = mkDefault "x86_64-linux";

  networking = {
    networkmanager.enable = mkDefault false;
    wireless = {
      enable = mkDefault true;
      userControlled.enable = mkDefault true;
    };
  };

  # XServer console settings
  console.useXkbConfig = true;
}
