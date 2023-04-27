args@{ config, lib, opitons, ... }:
let
  stateVersion = "22.11";
  pkgs = import ../nix args;
  releaseVersion = builtins.getEnv ("CYVIZEN_VERSION");
  chain = args // {
    inherit pkgs;
  };
in
with lib;
{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
    (import ../common-between/iso-oem-cyvizens.nix chain)
  ];

  specialisation = {
    non-interactive.configuration = {
      programs.bash.loginShellInit = "";
      services.getty.helpLine = ''
      '';
    };
  };

  boot.loader.timeout = mkForce
    0;
  boot.tmpOnTmpfs = true;
  boot.tmpOnTmpfsSize = "80%";

  services.openssh.enable = mkForce
    false;

  isoImage = {
    compressImage = false;
    contents = [
      {
        source = ./. + "/../../release/${releaseVersion}";
        target = "/nixos";
      }
      {
        source = /tmp/store;
        target = "/store";
      }
    ];
    includeSystemBuildDependencies = false;
    isoName = mkForce "cyvizen-oem.iso";
    volumeID = mkForce "nixos-cyvizen-${stateVersion}";
    storeContents = [ ];
  };

  environment.defaultPackages = pkgs.callPackage
    ../pkgs/iso.nix
    chain;

  hardware.enableAllFirmware = mkForce
    true;
  system.stateVersion = stateVersion;

  users.users = {
    root = {
      initialHashedPassword = "";
      shell = pkgs.bashInteractive;
    };
  };
  programs.bash.loginShellInit = ''
    rsync -a --info=progress2 /iso/nixos/ /tmp/cy/
    cd /tmp/cy/bin
    ./_start.js machine oem --factory
  '';
  services.getty.autologinUser = mkForce
    "root";
  services.getty.helpLine = mkForce
    ''
      Check above ^^ for any error messages, should any be present contact ISO author

      If no error messages then OEM system image is installed, type the following command
      and press <enter> key to shut down the machine
      -> systemctl shutdown
    '';

  networking.wireless.enable = true;
  networking.wireless.userControlled.enable = true;
  networking.networkmanager.enable = mkForce
    false;

  environment.shellAliases = {
    ls = "ls --color=auto";
    tree = "broot";
    cat = "bat";
    burntodisk = "nixos-install --no-root-passwd";
  };
}
