args@{ config, lib, utils, ... }:

with lib;
let
  pkgs = import ./nix args;
  sources = (import ./nix/sources.nix);
  isOEM = builtins.pathExists (./. + "/iso");
  userSetup = with builtins; if length
    (filter
      (LVMs:
        if head (if length (split "_" LVMs) > 1 then split "_" LVMs else split "-" LVMs) == "enc" then true else false)
      (attrNames (readDir /dev/cyvizen))) > 0 then
    true else
    false;
  intelGraphicsID =
    builtins.readFile
      (with pkgs; runCommand "self-i915" { } ''
        ${pciutils}/bin/lspci -nn | grep VGA | ${coreutils}/bin/cut -d':' -f4 | ${coreutils}/bin/head -c 4 > $out
      '');
  # Prioritize nautilus by default when opening directories
  mimeAppsList = pkgs.writeTextFile {
    name = "gnome-mimeapps";
    destination = "/share/applications/mimeapps.list";
    text = ''
      [Default Applications]
      inode/directory=nautilus.desktop;org.gnome.Nautilus.desktop
    '';
  };
  chain = args // {
    inherit pkgs;
    inherit sources;
  };
in
{
  imports = [
    # TODO hardened kernel
    # <nixpkgs/nixos/modules/profiles/hardened.nix>
    (import ./common-between/iso-oem-cyvizens.nix chain)
    ./common-between/filesystems.nix
    ./hardware-configuration.nix
    (import (if !isOEM && userSetup then ./profiles else ./profiles/noCyvizen.nix) chain)
    (import "${sources.home-manager}/nixos" chain)
    "${sources.sops-nix}/modules/sops"
    "${sources.impermanence}/nixos.nix"
  ];

  ################
  ##### BOOT #####
  ################
  boot = {
    initrd = {
      checkJournalingFS = true;
      luks = {
        reusePassphrases = true;
        fido2Support = true;
      };
    };
    loader = {
      generationsDir.copyKernels = true;
      efi.canTouchEfiVariables = false;
      # NOTE grub > systemd-boot for LUKS support at this time
      grub = {
        copyKernels = true;
        default = "saved";
        device = "nodev";
        efiInstallAsRemovable = true;
        efiSupport = true;
        enable = true;
        font = "${pkgs.fira-code}/share/fonts/truetype/FiraCode-VF.ttf";
        fontSize = 16;
        # TODO a Cyvizen GRUB theme
        # theme = pkgs.nixos-grub2-theme;
        version = 2;
      };
    };
    kernel.sysctl = {
      "vm.swappiness" = mkDefault 1;
    };
    # NOTE Intel 12th Gen requires direct mapping
    # https://nixos.wiki/wiki/Intel_Graphics
    kernelParams = [ "i915.force_probe=${intelGraphicsID}" ];
  };


  #######################
  ##### ENVIRONMENT #####
  #######################
  environment = {
    # Packages only downloaded to NIX Store, home-manager manages '/root' and Cyvizen users
    # NOTE ensures bulk of system is available without internet access on the OEM ISO
    defaultPackages =
      if isOEM then
        pkgs.callPackage (./. + "/pkgs") { } else
        mkForce [ ]; # https://xeiaso.net/blog/paranoid-nixos-2021-07-18 @Hardening
    pathsToLink = [
      "/share" # TODO upstream fix https://github.com/NixOS/nixpkgs/issues/47173
      "/share/nautilus-python/extensions"
    ];
    sessionVariables = {
      NAUTILUS_EXTENSION_DIR = "${config.system.path}/lib/nautilus/extensions-3.0";
      XDG_DATA_DIRS = [ "${mimeAppsList}/share" ];
      TERMINAL = "kitty";
    };
    systemPackages = mkDefault [ ];
    shells = [ pkgs.bashInteractive ];
    shellAliases = mkDefault {
      ls = "ls --color=auto";
      tree = "broot";
      cat = "bat";
    };
  };

  #################
  ##### FONTS #####
  #################
  fonts = {
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    fontconfig = {
      enable = true;
      hinting.autohint = false;
      useEmbeddedBitmaps = true;
      defaultFonts = mkDefault {
        serif = [ "Andika" "Fira Sans" ];
        sansSerif = [ "Oxygen-Sans" ];
        monospace = [ "Fira Code" ];
      };
    };
    fonts = with pkgs; [
      fira-code
      font-awesome
      oxygenfonts
      andika
      fira
      merriweather
      roboto
    ];
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  ######################
  ##### NETWORKING #####
  ######################
  networking = {
    networkmanager = {
      unmanaged = mkDefault [
        # "*"
        # "except:type:wwan"
        # "except:type:gsm"
      ];
    };
    wireless = {
      scanOnLowSignal = mkDefault false;
    };
    # NOTE: needs to be disabled on Gen11 to prevent 1.5min scan of network interfaces trying to find DHCP
    useDHCP = lib.mkDefault true;
    # NOTE gen 12 has wlan0 instead of newer naming scheme
    # interfaces.wlp0s20f3.useDHCP = true;
    firewall = {
      enable = mkDefault true;
      allowedTCPPorts = mkDefault [ ];
      allowedUDPPorts = mkDefault [ ];
    };
  };
  # NOTE post-OEM setup ensure bluetooth powered off by default
  hardware.bluetooth.powerOnBoot = mkOverride 500 false;
  hardware.sensor.iio.enable = mkDefault true;

  ###############
  ##### NIX #####
  ###############
  nix = {
    enable = true;
    optimise.automatic = true;
    readOnlyStore = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    settings = {
      auto-optimise-store = true;
      allowed-users = [ "@wheel" ];
    };
  };

  ####################
  ##### PROGRAMS #####
  ####################
  programs = {
    dconf.enable = true;
    extra-container.enable = true;
    file-roller.enable = true;
    firejail.enable = true;
    gnome-disks.enable = true;
    nix-ld.enable = true; # https://github.com/Mic92/nix-ld dynamic linker for imported applications
  };

  ########################
  ##### LOCALIZATION #####
  ########################
  i18n.defaultLocale = mkDefault "en_AU.UTF-8";
  location.provider = mkDefault "geoclue2";
  time.timeZone = mkDefault "Australia/Brisbane";

  ################################
  ##### SECURITY / HARDENING #####
  ################################
  sops = {
    age = {
      keyFile = "/etc/nixos/self/age-key.txt";
      generateKey = false;
    };
    defaultSopsFile = "/etc/nixos/self/sops.json";
    defaultSopsFormat = "json";
    validateSopsFiles = false;
  };

  # TODO custom kernel
  # boot.kernel.randstructSeed = "";
  # NOTE unproven attack vector at heavy performance cost, continue permitting MultiThreading unless it becomes a future concern.
  # security.allowSimultaneousMultithreading = true;
  # NOTE more + than - in allowing this, both here and in servers
  # security.allowUserNamespaces = true;
  security = {
    sudo = {
      enable = mkDefault true;
      wheelNeedsPassword = false;
      execWheelOnly = true;
    };
    doas.enable = false;
    please.enable = false;
    polkit.enable = true;
    chromiumSuidSandbox.enable = true;
    tpm2 = {
      enable = true;
      pkcs11.enable = true;
      tctiEnvironment.enable = true;
    };
  };

  systemd.coredump.enable = false;


  ####################
  ##### SERVICES #####
  ####################
  services = {
    accounts-daemon.enable = true;
    aria2 = {
      enable = true;
      downloadDir = "/cyvizen/home/Downloads";
      openPorts = true;
    };
    avahi = {
      enable = true;
      nssmdns = true;
      reflector = mkDefault true;
      openFirewall = true;
    };
    btrfs.autoScrub.enable = true;
    flatpak.enable = true;
    fwupd.enable = true;
    gnome = {
      core-os-services.enable = mkForce false;
      core-utilities.enable = false;
      at-spi2-core.enable = true;
      tracker.enable = false;
      evolution-data-server.enable = true;
      # NOTE keepass integration goes direct to libsecret, keyring is tautological
      gnome-keyring.enable = false;
      tracker-miners.enable = false;
      gnome-browser-connector.enable = true;
      sushi.enable = true;
    };
    hardware = {
      bolt.enable = true;
      openrgb = {
        enable = true;
        motherboard = "intel";
      };
    };
    opensnitch = {
      enable = mkDefault true;
      settings = {
        DefaultAction = "deny";
        DefaultDuration = "until restart";
        Firewall = "iptables";
        InterceptUnknown = false;
        LogLevel = 3;
        ProcMonitorMethod = "ebpf";
      };
    };
    # NOTE upstream https://github.com/NixOS/nixpkgs/pull/94055
    packagekit.enable = mkDefault false;
    power-profiles-daemon.enable = true;
    printing.enable = true;
    # NOTE gnome power-profiles-daemon replaces tlp
    # tlp.enable = true;
    sysprof.enable = true;
    udisks2.enable = true;
    udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
    upower.enable = true;
    xserver = {
      enable = mkDefault false;
      layout = "us";
      libinput = {
        enable = true;
        touchpad = {
          # NOTE GNOME not respecting libinput, instead forcing default values from xinput
          # to correct x related input settings need to be handled by xsession.initExtra with xinput commands
          tapping = mkDefault true;
          tappingDragLock = mkDefault true;
          sendEventsMode = mkDefault "disabled-on-external-mouse";
          scrollMethod = mkDefault "twofinger";
          naturalScrolling = mkDefault false;
          disableWhileTyping = mkDefault true;
        };
      };
      updateDbusEnvironment = true;
      displayManager = {
        gdm = {
          enable = mkDefault false;
          wayland = false;
        };
      };
      desktopManager = {
        gnome = {
          enable = mkDefault false;
          extraGSettingsOverrides = ''
            [org.gnome.shell]
            favorite-apps = ['librewolf.desktop', 'nixos-manual.desktop', 'kitty.desktop']
            welcome-dialog-last-shown-version = '9999999999'

            [org.gnome.desktop.privacy]
            disable-camera = true
            disable-microphone = true
            old-files-age = uint32 7
            recent-files-max-age = 7
            remember-app-usage = true
            remember-recent-files = true
            remove-old-temp-files = true
            remove-old-trash-files = true
            report-technical-problems = false
            send-software-usage-stats = false
            usb-protection = true
            usb-protection-level = 'lockscreen'

            [org.gnome.desktop.screensaver]
            user-switch-enabled = false

            [org.gnome.login-screen]
            banner-message-enable = true
            banner-message-text = 'Welcome Back Cyvizen, Please Login'
            disable-user-list = true
            logo = ${./. + "/artwork/Cyvizen-Logo.jpg"}

            [org.gnome.desktop.background]
            picture-uri = '${./. + "/artwork/Cyvizen-Background.jpg"}'
            picture-uri-dark = '${./. + "/artwork/Cyvizen-Background.jpg"}'

            [org.gnome.desktop.default-applications.terminal]
            exec = 'kitty'
            exec-arg = ' '

            [org.gnome.desktop.lockdown]
            user-administration-disabled = true
            disable-user-switching = true
            # enabling the next toggle crashes the machine
            # disable-log-out = true

            [org.gnome.desktop.media-handling]
            autorun-never = true

            [org.gnome.desktop.notifications]
            show-in-lock-screen = false

            [org.gnome.desktop.peripherals.touchpad]
            tap-to-click = true
            natural-scroll = false
          '';
          extraGSettingsOverridePackages = with pkgs; with gnome; [
            gnome-shell
            gsettings-desktop-schemas
          ];
        };
        xterm.enable = false;
      };
      excludePackages = with pkgs; [
        xterm
      ];
    };
  };

  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  # NOTE Cyvizen provides a more unified update path than NixOS or Home-Manager are able to at this time & is used for application stability
  system.autoUpgrade.enable = false;

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "22.11";

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
