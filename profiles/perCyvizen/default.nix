args@{ config
, lib
, machine
, userName
, utils
, ...
}:
let
  pkgs = import ../../nix args;
  systemdRunAfter = (target: {
    enable = true;
    after = [ "${target}" ];
    wantedBy = [ "${target}" ];
    partOf = [ "${target}" ];
  });
  gnomeSettings = [
    "SessionManager logout-prompt false"
    "desktop.default-applications.terminal exec 'kitty'"
    "desktop.default-applications.terminal exec-arg ' '"
    "desktop.screensaver user-switch-enabled false"
    "settings-daemon.plugins.color night-light-enabled true"
    "settings-daemon.plugins.color night-light-schedule-automatic true"
    "settings-daemon.plugins.color night-light-temperature 1900"
    "settings-daemon.plugins.power sleep-inactive-battery-type 'suspend'"
    "shell welcome-dialog-last-shown-version '9999999999'"
  ] ++ config.cyvizen.gnomeSettings;
  gnomeExtensions = [
    # NOTE Order Important, do not sort (right -> left)
    "pomodoro@arun.codito.in"
    "espresso@coadmunkee.github.com"
    "another-window-session-manager@gmail.com"
    "nothing-to-say@extensions.gnome.wouter.bolsterl.ee"
    "lockkeys@vaina.lt"
    "gnome-shell-trash-extension"
    "wireless-hid@chlumskyvaclav.gmail.com"
    "workspace-indicator@gnome-shell-extensions.gcampax.github.com"

    # Hidden
    "advanced-alt-tab@G-dH.github.com"
    "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
    "autoselectheadset@josephlbarnett.github.com"
    "burn-my-windows@schneegans.github.com"
    "gnome-fuzzy-app-search@gnome-shell-extensions.Czarlie.gitlab.com"
    "noannoyance@daase.net"
    "replaceActivitiesText@pratap.fastmail.fm"
    "Vitals@CoreCoding.com"
  ];
  dconfSettings = [
    "advanced-alt-tab-window-switcher/app-switcher-popup-fav-apps false"
    "advanced-alt-tab-window-switcher/app-switcher-popup-filter 2"
    "advanced-alt-tab-window-switcher/app-switcher-popup-hide-win-counter-for-single-window true"
    "advanced-alt-tab-window-switcher/app-switcher-popup-raise-first-only true"
    "advanced-alt-tab-window-switcher/app-switcher-popup-search-pref-running true"
    "advanced-alt-tab-window-switcher/app-switcher-popup-titles true"
    "advanced-alt-tab-window-switcher/switcher-popup-monitor 2"
    "advanced-alt-tab-window-switcher/switcher-popup-position 2"
    "advanced-alt-tab-window-switcher/win-switcher-popup-filter 2"
    "advanced-alt-tab-window-switcher/wm-always-activate-focused true"
    "another-window-session-manager/enable-autorestore-sessions true"
    "another-window-session-manager/restore-at-startup-without-asking true"
    "burn-my-windows/destroy-dialogues true"
    "burn-my-windows/disable-on-battery false"
    "burn-my-windows/fire-close-effect false"
    "burn-my-windows/glide-close-effect false"
    "burn-my-windows/hexagon-animation-time 500"
    "burn-my-windows/hexagon-close-effect false"
    "burn-my-windows/hexagon-open-effect true"
    "burn-my-windows/incinerate-animation-time 1200"
    "burn-my-windows/incinerate-close-effect true"
    "burn-my-windows/incinerate-color \"'rgb(1,255,255)'\""
    "burn-my-windows/incinerate-use-pointer true"
    "espresso/allow-override true"
    "espresso/enable-fullscreen true"
    "espresso/has-battery true"
    "espresso/show-indicator true"
    "espresso/show-notifications true"
    "lockkeys/style \"'show-hide'\""
    "nothing-to-say/icon-visibility \"'when-recording'\""
    "nothing-to-say/keybinding-toggle-mute \"['Pause']\""
    "nothing-to-say/play-feedback-sounds false"
    "nothing-to-say/show-osd true"
    "replaceActivitiesText/icon-path \"'/etc/nixos/artwork/Cyvizen-Logo.jpg'\""
    "replaceActivitiesText/icon-size 2"
    "replaceActivitiesText/text \"''\""
    "vitals/hot-sensors \"['__temperature_avg__', '_memory_usage_', '_processor_usage_', '__network-rx_max__']\""
    "vitals/position-in-panel 0"
    "vitals/show-fan false"
    "vitals/show-voltage false"
    "vitals/storage=path \"'/cyvizen/'\""
    "vitals/update-time 10"
  ];
  autoEspresso = [ ] ++ config.cyvizen.autoEspresso;
  flatpakRemotes = [ ] ++ config.cyvizen.flatpakRemotes;
  pkgsFirejail = with pkgs; callPackage ../../pkgs/firejail.nix chain ++ config.cyvizen.firejail;
  pkgsNormal = utils.removePackagesByName (with pkgs; callPackage ../../pkgs chain ++ config.cyvizen.pkgs) config.cyvizen.pkgsExcluded;
  openSnitch = {
    allow = config.cyvizen.opensnitch.allow.pkgs;
    block = config.cyvizen.opensnitch.block.pkgs;
    prefix = "/opensnitchd/rules/";
    template = (rules: {
      enable = true;
      text = builtins.toJSON {
        name = rules.name;
        enabled = true;
        precedence = false;
        action = rules.action;
        duration = "always";
        operator = {
          type = "regexp";
          sensitive = false;
          operand = "process.path";
          data = "\\/${rules.name}\$";
        };
      };
    });
  };
  chain = args // {
    inherit pkgs;
  };
in
with lib;
{
  system.nixos.tags = [ "${userName}" ];

  imports = [
    (import ./home-manager.nix chain)
    (import ./stabilisation.nix chain)
    # NOTE this will not work with NixOS config due to closure evalution
    # NOTE cyvizen per user configuration must be last to load to ensure priority
    (import (./. + "/../../cyvizens/${userName}/configuration.nix") chain)
  ];

  fileSystems = {
    "/cyvizen" = {
      device = "/dev/mapper/cyvive";
      fsType = "btrfs";
      options = [ "subvol=cyvizen" "compress=zstd" "noatime" "autodefrag" ];
      neededForBoot = true;
    };
    "/self" = {
      device = "/dev/mapper/cyvive";
      fsType = "btrfs";
      options = [ "subvol=self" "compress=zstd" "noatime" "autodefrag" ];
      neededForBoot = true;
    };
  };

  swapDevices = [{ device = "/dev/mapper/cyvive-swap"; }];

  services.btrfs.autoScrub.fileSystems = [
    "/cyvizen"
    "/self"
  ];

  boot.initrd.luks.devices = {
    "cyvive" = {
      device =
        if builtins.pathExists "/dev/cyvizen/enc_${userName}" then "/dev/cyvizen/enc_${userName}" else "/dev/cyvizen/enc-${userName}";
      bypassWorkqueues = true;
      preLVM = false;
    };
    "cyvive-swap" = {
      device =
        if builtins.pathExists "/dev/cyvizen/enc_${userName}_swap" then "/dev/cyvizen/enc_${userName}_swap" else "/dev/cyvizen/enc-${userName}-swap";
      bypassWorkqueues = true;
      preLVM = false;
    };
  };

  environment.persistence = {
    "/cyvizen/machines/${machine.id}" = {
      hideMounts = true;
      directories = pkgs.callPackage (../saveTo/cyvizen/nixos.nix) { }
        ++ config.cyvizen.saveTo.cyvizen.nixos;
    };
    "/self" = {
      hideMounts = true;
      directories = pkgs.callPackage (../saveTo/machine/nixos.nix) { }
        ++ config.cyvizen.saveTo.machine.nixos;
      users.${userName} = {
        directories = lib.lists.forEach
          (pkgs.callPackage (../saveTo/machine/home.nix) { }
            ++ config.cyvizen.saveTo.machine.home ++ [ "Offline" ])
          (dir: {
            directory = "${dir}";
            user = userName;
            group = userName;
          });
      };
    };
  };

  # NOTE Custom link to restore /etc/opensnitchd/rules link as *much* easier to write data to /etc
  system.activationScripts.linkOpenSnitchRules = lib.stringAfter
    [ "var" ]
    ''
      mkdir -p /var/lib/opensnitch/
      mkdir -p /etc/opensnitchd/rules/
      ln -sfn /etc/opensnitchd/rules /var/lib/opensnitch/rules
    '';
  environment.etc = with lib; with lib.strings; attrsets.genAttrs
    (lists.forEach openSnitch.allow (name: concatStrings [ openSnitch.prefix name ".json" ]))
    (
      name: openSnitch.template {
        name = "${removeSuffix ".json" (removePrefix openSnitch.prefix name)}";
        action = "allow";
      }
    )
  // attrsets.genAttrs
    (lists.forEach openSnitch.block (name: concatStrings [ openSnitch.prefix name ".json" ]))
    (
      name: openSnitch.template {
        name = "${removeSuffix ".json" (removePrefix openSnitch.prefix name)}";
        action = "reject";
      }
    );

  programs.adb.enable = true;
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };
  programs.firejail.wrappedBinaries = with lib.attrsets; genAttrs
    (builtins.map (package: package.pname) pkgsFirejail)
    (
      name: {
        executable = "${getBin pkgs.${name}}/bin/${name}";
        profile = "${pkgs.firejail}/etc/firejail/${name}.profile";
      }
    );

  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    displayManager.autoLogin = {
      enable = true;
      user = "${userName}";
    };
    desktopManager.gnome.enable = true;
  };

  # NOTE: workaround to allow autoLogin with nixos 22.11
  systemd.services = {
    "getty@tty1".enable = false;
    "autovt@tty1".enable = false;
    cyvizen-flatpakRemotes = with pkgs; {
      script = ''
        ${flatpak}/bin/flatpak remote-add --if-not-exists ${builtins.concatStringsSep "; ${flatpak}/bin/flatpak remote-add --if-not-exists " flatpakRemotes};
      '';
    } // systemdRunAfter "flatpak-system-helper.service";
    cyvizen-machineInfo = with pkgs; {
      script = ''
        ${coreutils}/bin/mkdir -p /cyvizen/machines/${machine.id}/.info/
        # | true appended as will access unpermitted items and trigger a flase failure
        ${coreutils}/bin/cp -r /sys/class/dmi/id/* /cyvizen/machines/${machine.id}/.info/ | true
      '';
    } // systemdRunAfter "graphical-session.target";
  };

  systemd.user.services = with pkgs; {
    cyvizen-gnomeSetup = {
      script = with builtins; ''
        ${glib}/bin/gsettings set org.gnome.${concatStringsSep "; ${glib}/bin/gsettings set org.gnome." gnomeSettings};

        # Configure Gnome Shell Extensions
        ${dconf}/bin/dconf write /org/gnome/shell/extensions/${concatStringsSep "; ${dconf}/bin/dconf write /org/gnome/shell/extensions/" dconfSettings};

        # Configure Espresso
        ${dconf}/bin/dconf write /org/gnome/shell/extensions/espresso/inhibit-apps "['${concatStringsSep ".desktop', '" autoEspresso}.desktop']";

        # Configure WorkSpace Names
        ${dconf}/bin/dconf write /org/gnome/desktop/wm/preferences/workspace-names "['${concatStringsSep "', '" config.cyvizen.workspace.names}']";

        # NOTE extensions work best when loaded _after_ dconf keys populated
        # Enable Gnome Shell Extensions
        ${gnome.gnome-shell}/bin/gnome-extensions enable ${concatStringsSep "; ${gnome.gnome-shell}/bin/gnome-extensions enable " gnomeExtensions};

      '';
    } // systemdRunAfter "gnome-session-initialized.target";
  };

  users.extraGroups.${userName}.gid = 499;
  users.extraUsers.${userName} = {
    createHome = true;
    group = "${userName}";
    passwordFile = config.sops.secrets.${userName}.path;
    home = "/home/${userName}";
    isNormalUser = true;
    packages = pkgsNormal;
    shell = pkgs.bashInteractive;
    extraGroups = [
      config.users.groups.keys.name
      "audio"
      "i2c"
      "lp"
      "networkmanager"
      "scanner"
      "tss"
      "users"
      "wheel"
    ] ++ config.cyvizen.extraGroups;
    uid = 1000;
  };
}
