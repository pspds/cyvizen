args@{ config, lib, userName, pkgs, ... }:
with lib;
{
  imports = [
    (import ./nixos.nix args)
    (import ./home-manager.nix args)
  ];


  ############
  # PACKAGES #
  ############
  # NOTE packages you require that are not available as NixOS Options or Home-Manager Options
  # you can find a full package list at: https://search.nixos.org/packages?channel=22.11&from=0&size=50&sort=relevance&type=packages
  cyvizen.pkgs = with pkgs; [
  ];

  # NOTE if you dislike a bundled package add its name below and Cyvizen will not install it
  cyvizen.pkgsExcluded = with pkgs; [
  ];

  # NOTE Firejail attempts to isolate packages from eachother via SecComp and AppArmor profiles it _might_ break packages and has compatibility challenges with AppImages (which some software in NixPkgs is bundled as)
  # NOTE Firejail needs a profile to work, so its package base is limited, you can locate available profiles using the command `cyvizen-firejail-profile` and then search for matching nix packages the usual way
  # NOTE any package listed in "firejail" *must* not be listed in "pkgs"
  cyvizen.firejail = [
  ];

  # NOTE remove backends for FlatPak packages
  # use the format "NAME URI"
  cyvizen.flatpakRemotes = [
    "flathub https://flathub.org/repo/flathub.flatpakrepo"
  ];

  ###################################
  # OpenSnitch Application Firewall #
  ###################################
  # NOTE OpenSnitch is a powerful application firewall full rules information is available https://github.com/evilsocket/opensnitch/wiki/Rules
  # this is a drastically simplified interface & application of rules for convenience of Cyvizens, you can still apply complex rules through the UI, or by adding your complex rules to `environment.etc.openSnitch<rule-name>` in `nixos.nix`
  # ideally you would add complex rules in accordance with https://github.com/evilsocket/opensnitch/wiki/Rules#best-practices for your situation
  # NOTE complex rules should filter by: <executable> + <command line> + (... more parameters...)
  # This simple implementation will ALLOW ALL traffic for each of the sofware listed
  cyvizen.opensnitch.allow.pkgs = [
    "..audacity-wrapped-wrapped"
    ".Fritzing-wrapped"
    ".YACReader-wrapped"
    ".electron-wrapped"
    ".evolution-wrapped"
    ".font-manager-wrapped"
    ".godot-wrapped"
    ".mepo-wrapped"
    ".obs-wrapped"
    ".openrgb-wrapped"
    ".pidgin-wrapped"
    ".qgis-wrapped"
    ".sayonara-wrapped"
    "NetworkManager"
    "Steam"
    "avahi-daemon"
    "chromium"
    "cups-browsed"
    "cupsd"
    "freshclam"
    "ipp"
    "librewolf"
    "niv"
    "nix"
    "node"
    "nscd"
    "python3.10"
    "scanimage"
    "snmp"
    "ssh"
    "systemd-timesyncd"
  ];

  cyvizen.opensnitch.block.pkgs = [
    ".gvfsd-http-wrapped"
    ".gvfsd-smb-browse-wrapped"
  ];

  # NOTE following feature is under development
  # # List of domains to block for all software
  # cyvizen.opensnitch.block.domains = [
  # ];
  # # List of IPs to block for all software
  # cyvizen.opensnitch.block.domainsRegex = [
  # ];

  ######################
  # User (self) Config #
  ######################
  # NOTE additional groups that your user needs access to
  cyvizen.extraGroups = [
  ];


  ##################
  # GNOME Settings #
  ##################
  # NOTE `gsettings command` allows you to locate values for GNOME Settings
  # gsettings set org.gnome.* is preprended to each of these lines & gsettings command is executed for each line
  cyvizen.gnomeSettings = [
    "desktop.interface color-scheme 'prefer-dark'"
    "desktop.privacy disable-camera true"
    "desktop.privacy disable-microphone true"
    "shell favorite-apps \"['librewolf.desktop', 'nixos-manual.desktop', 'kitty.desktop']\""
  ];
  # NOTE GNOME Shell Extensions to enable, ensure you add the relevant extension to cyvizen.pkgs as well
  cyvizen.gnomeExtensions = [
  ];
  # NOTE GNOME Shell Extensions configuration settings see `dconf-editor`
  # dconf write /org/gnome/shell/extensions/* is preprended to each of these lines & dconf command is executed for each line
  cyvizen.dconfSettings = [
  ];
  # NOTE espresso prevents the machine from automatically sleeping, hibernating or displaying the lock screen. It is useful for watching videos, team meetings and other
  cyvizen.autoEspresso = [
    "jitsi-meet-electron"
  ];

  cyvizen.workspace.names = [
    "FireWall"
    "Generic"
    "Web"
  ];


  ###################
  # SAVED LOCATIONS #
  ###################
  # NOTE Add directories relative to `~/` to be saved to your Cyvizen & shared to all machines your Cyvizen is linked to
  cyvizen.saveTo.cyvizen.home = [
  ];

  # NOTE specific files relative to `~/` to symlink if unecessary to save entire directory
  cyvizen.saveTo.cyvizen.homeFiles = [
  ];

  # NOTE the intention is for porting sensible machine agnostic items between machines
  # see: https://github.com/nix-community/impermanence#nixos for full options if your need advanced functionality
  # directories are from `/`
  cyvizen.saveTo.cyvizen.nixos = [
  ];

  # NOTE the intention is for large files that aren't wanted in your encrypted Cyvizen and are unsuitable for tmpfs due to its epheremal nature i.e. `~/.cache`
  # see: https://github.com/nix-community/impermanence#nixos for full options if your need advanced functionality
  # directories are from `~/` and will be saved to this machine only under `/nix/self`
  cyvizen.saveTo.machine.home = [
    "Downloads"
  ];

  # NOTE the intention is for files that can be re-downloded from internet i.e. clamav signatures but aren't suitable for tmpfs (RAM) due to size
  # see: https://github.com/nix-community/impermanence#nixos for full options if your need advanced functionality
  # directories are from `/` and will be saved to this machine only under `/nix/self`
  cyvizen.saveTo.machine.nixos = [
  ];

  # NOTE Add directories relative to `~/` to be ignored by the command `cyvizen-impermanence`
  cyvizen.saveTo.ignore = [
  ];
}
