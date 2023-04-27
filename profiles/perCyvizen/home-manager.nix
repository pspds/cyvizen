args@{ config
, lib
, machine
, userName
, pkgs
, sources
, ...
}:
let
  cyvizenDocs = "file:///home/${userName}/Offline/cyvizen/index.html";
  impermanenceIgnore = (lib.lists.concatMap (dirs: pkgs.callPackage (./. + "/../${dirs}.nix") { }) [
    "saveTo/cyvizen/home"
    "saveTo/machine/home"
    "saveTo/ignore"
  ])
  ++ config.cyvizen.saveTo.cyvizen.home
  ++ config.cyvizen.saveTo.machine.home
  ++ config.cyvizen.saveTo.ignore;
  dirsToIgnore = with builtins; concatStringsSep "/*' ! -path '*/" impermanenceIgnore;
  shells = {
    enableBashIntegration = true;
    enableFishIntegration = false;
    enableZshIntegration = false;
  };
in
with lib;
{
  home-manager.users.${userName} = { lib, ... }: {
    imports = [
      "${sources.impermanence}/home-manager.nix"
    ];

    nixpkgs.config = import ../../templates/config.nix;

    xdg = {
      enable = true;
      configFile = {
        "nixpkgs/config.nix".source = ../../templates/config.nix;
        "autostart/opensnitch_ui.desktop".source = builtins.storePath "${pkgs.opensnitch-ui}/share/applications/opensnitch_ui.desktop";
      };
      dataFile = { };
      userDirs = {
        enable = mkForce true;
        # NOTE conflict with impermanence requires either false, or impermanence to be moved to stabilisation
        createDirectories = mkForce false;
      };
    };

    home.persistence."/cyvizen/home" = {
      # NOTE btrfs storage works better with symlinks
      # NOTE impermanence home-manager **must** have at least one bind-mount or will crash
      # NOTE home-manager managed applications i.e. `.librewolf` & `.recoll` cannot install via symlink as they fail the _present_ in `~/` test in home-manager they must be bind-mounted
      directories = [
        ".librewolf"
        ".recoll"
      ] ++ lib.lists.forEach
        (pkgs.callPackage (../saveTo/cyvizen/home.nix) { }
          ++ config.cyvizen.saveTo.cyvizen.home)
        (dir: {
          directory = "${dir}";
          method = "symlink";
        });

      # files are symlinked (symbolic links)
      files = config.cyvizen.saveTo.cyvizen.homeFiles;
      allowOther = true;
    };

    fonts.fontconfig.enable = true;

    programs = {
      home-manager.enable = true;
      # aria2.enable = true; # multi-part download manager
      bash = {
        # Bash used as default shell, this can be changed but its a sensible default
        enable = mkDefault true;
        enableCompletion = true;
        historyControl = [ "erasedups" "ignorespace" ];
        historyIgnore = [ ]; # commands that should not be saved to history
        initExtra = ''
          # NOTE completion temporarily unavailable
          # source <(/etc/nixos/bin/cyvizen completion)
        ''; # extra commands needed to interactive shell initialise
        shellAliases = with lib; {
          # replacements with generally better than default options
          cyvizen = "cd /etc/nixos/bin; ./_start.js";
          cyvizen-impermanence = "nix-shell -p tree --run \"find ~/ -xdev -depth ! -path '*/${dirsToIgnore}/*' ! -type l ! -type d | tree -a --fromfile\"";
          "nix-channel" = "echo \"Disabled by Cyvizen for system stability, use 'niv' https://github.com/nmattia/niv in /cyvizen/nixos/";
          cat = mkDefault "bat";
          ls = mkDefault "exa";
          top = mkDefault "bpytop";
          tree = mkDefault "broot";
          rm = mkDefault "trash put";
          cd = mkDefault "z";
        };
      };
      bashmount.enable = mkDefault true; # easily mount removable media from terminal https://github.com/jamielinux/bashmount
      bat = {
        enable = true;
        #        extraPackages = [ ]; # TODO sensible defaults
        themes = { };
      };
      broot = {
        enable = true; # better version of tree
      } // shells;
      direnv = {
        # environmental switcher per directory, helpful for development and nix management
        enable = true;
      } // shells;
      exa.enable = true;
      librewolf = {
        enable = true; # Master reference https://github.com/librewolf-community/settings/blob/master/librewolf.cfg
        # NOTE Cyvizen focus is on Anonymity > Privacy disable items that increase standing out from the crowd
        # https://librewolf.net/docs/testing/
        # https://coveryourtracks.eff.org/
        # https://themarkup.org/the-breakdown/2020/09/22/i-scanned-the-websites-i-visit-with-blacklight-and-its-horrifying-now-what
        # https://www.cookiestatus.com/
        settings = {
          "webgl.disabled" = false;
          "privacy.window.maxInnerWidth" = 1920;
          "privacy.window.maxInnerHeight" = 1080;
          "privacy.resistFingerprinting.letterboxing" = true;
          "privacy.clearOnShutdown.cache" = false;
          "privacy.clearOnShutdown.cookies" = false;
          "privacy.clearOnShutdown.downloads" = false;
          "privacy.clearOnShutdown.history" = false;
          "privacy.clearOnShutdown.openWindows" = false;
          "privacy.clearOnShutdown.sessions" = false;
          "media.peerconnection.ice.no_host" = false;
          # "identity.fxaccounts.enabled" = true; # TODO (external) FireFox won't allow sync with privacy settings
          "middlemouse.paste" = false;
          "general.autoScroll" = true;
          "browser.startup.homepage_override.mstone" = "ignore";
          "startup.homepage_override_url" = cyvizenDocs;
          "startup.homepage_welcome_url" = cyvizenDocs;
          "startup.homepage_welcome_url.additional" = "";
          "browser.startup.homepage" = cyvizenDocs;
          "browser.engagement.ctrlTab.sortByRecentlyUsed" = true;
          "security.OCSP.enabled" = 0; # https://librewolf.net/docs/faq/#im-getting-sec_error_ocsp_server_error-what-can-i-do NOTE required for surfshark & most vpn clients at this time
        };
      };
      fzf = {
        enable = true;
      } // shells;
      gallery-dl.enable = mkDefault true; # access many "free" images and download via command line https://github.com/mikf/gallery-dl/blob/master/docs/supportedsites.md
      git = {
        enable = true;
        # package = pkgs.gitAndTools.gitFull;
        delta = {
          enable = true;
          options = { };
        };
      };
      # gitui.enable = true;
      lazygit.enable = mkDefault true;
      kitty = {
        # https://www.reddit.com/r/linux/comments/sfz3ne/comment/hutwvnf/?utm_source=reddit&utm_medium=web2x&context=3
        # TODO sensible defaults
        enable = true;
      };
      nix-index = {
        enable = true;
      } // shells;
      obs-studio.enable = mkDefault true;
      pidgin = {
        enable = mkDefault true;
      };
      powerline-go = {
        enable = mkDefault true;
        modules = [
          "cwd"
          "direnv"
          "exit"
          "gitlite"
          "jobs"
          "load"
          "newline"
          "nix-shell"
          "perms"
          "root"
          "shell-var"
          "ssh"
          "termtitle"
        ];
        settings = { };
      };
      watson.enable = mkDefault true; # track your time on projects
      yt-dlp.enable = mkDefault true; # download youtube
      zoxide.enable = true;
    };

    services = {
      # barrier
      betterlockscreen.enable = true;
      devilspie2.enable = true;
      # fusuma.enable = true; # multi-touch for touchpad / guestures
      lorri.enable = true;
      # recoll.enable = true; # TODO global document search!
      # unison # cross platform syncing (use to get things into this machines)
    };
    # NOTE Cyvizen provides a more unified update path than NixOS or Home-Manager are able to at this time & is used for application stability
    services.home-manager.autoUpgrade.enable = mkForce false;
    home = {
      homeDirectory = "/home/${userName}";
      username = "${userName}";
      stateVersion = "22.11";
    };
  };
}
