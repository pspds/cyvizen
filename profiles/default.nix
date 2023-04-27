args@{ config, lib, utils, ... }:
let
  isEmergency = builtins.pathExists (/etc/nixos/self/enableEmergency);
  # NOTE /sys/class/dmi/id relies on /dev/mem which is mapped into RAM from BIOS by the Kernel. NixOS cannot access these values during build as Kernel not loaded in build phase. Working around this by creatings a file containing this ID in /etc/nixos/self
  machine = with builtins; fromJSON (readFile /etc/nixos/self/machine.json);
  encUsers = with builtins; filter
    (userNameString:
      let
        isUser =
          if length (split "_" userNameString) > 1 then split "_" userNameString else split "-" userNameString;
        lastUser = lib.lists.last isUser;
      in
      if head isUser == "enc" && lastUser != "swap" && pathExists
        (./. + "/../cyvizens/${lastUser}") then true else false)
    (attrNames (readDir /dev/cyvizen));
  userNames = with builtins; map (x: lib.lists.last (if length (split "_" x) > 1 then split "_" x else split "-" x)) encUsers;
  userName = lib.lists.last userNames;
  chain = args // {
    inherit userName;
    inherit userNames;
    inherit machine;
  };
in
with lib;
{
  imports =
    if isEmergency
    then [ ./emergency.nix ]
    else
    # NOTE "is" appropriate subscription feature enabled
      (if builtins.pathExists ./is then [
        (import ./is chain)
      ] else [
        (import ./perCyvizen chain)
      ]);

  options = {
    self = mkOption {
      type = types.anything;
      default = { };
    };
    cyvizen = mkOption {
      type = types.anything;
      default = { };
    };
  };

  config = {
    users.mutableUsers = false;

    networking = with builtins; {
      networkmanager.enable = true;
      wireless.enable = false;
      hostName = mkDefault (substring 1 99 machine.id);
      hostId = mkDefault (substring 1 8 machine.id);
    };

    services = {
      logind.lidSwitch = "suspend-then-hibernate";
    };
    programs = {
      fuse.userAllowOther = true;
      mepo.enable = true; # map application
      extra-container.enable = true; # NixOS containers without host system rebuilds
    };

    # NOTE machine configuration
    # this will most likely roll up into machine.json as config.machine seems to circular ref
    self = {
      isGuest = builtins.pathExists (/etc/nixos/self/enableGuest);
      isMultiUser = builtins.pathExists (/etc/nixos/self/enableMultiUser);
      isEmergency = builtins.pathExists (/etc/nixos/self/enableEmergency);
      isOEM = builtins.pathExists (../iso);
    };

    sops.secrets = lib.attrsets.genAttrs userNames
      (userName: {
        sopsFile = "/etc/nixos/cyvizens/${userName}/sops.json";
        neededForUsers = true;
      });
  };
}
