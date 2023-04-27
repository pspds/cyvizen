{ config, lib, pkgs, ... }:
with lib;
{
  services.getty.autologinUser = "root";
  system.nixos.tags = [ "Emergency" ];

  users.allowNoPasswordLogin = true;
  users.users.root.initialHashedPassword = "";

  environment.defaultPackages = pkgs.callPackage ../pkgs/emergency.nix { inherit pkgs; };

  hardware = {
    sane.enable = mkForce false;
  };

  networking = {
    firewall.enable = mkForce false;
    wireless = {
      enable = true;
      userControlled.enable = true;
    };
    networkmanager.enable = mkForce false;
  };

  services = {
    aria2.enable = mkForce false;
    avahi.enable = mkForce false;
    clamav.daemon.enable = mkForce false;
    clamav.updater.enable = mkForce false;
    flatpak.enable = mkForce false;
    hardware.openrgb.enable = mkForce false;
    gnome = {
      at-spi2-core.enable = mkForce false;
      evolution-data-server.enable = mkForce false;
      gnome-browser-connector.enable = mkForce false;
      sushi.enable = mkForce false;
    };
    opensnitch.enable = mkForce false;
    printing.enable = mkForce false;
    xserver.enable = mkForce false;
  };
}
