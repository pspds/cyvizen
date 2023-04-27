args@{ lib, pkgs, userName, ... }:
# NOTE NixOS and Home-Manager are different
# Home-Manager is an effective method for per user based applications, but in reality
# everything done in Home-Manager can also be done in NixOS it just makes management
# easier and leverages the communities work
#
# Cyvizen classifies NixOS settings > Home-Manager so where options available with no
# advantage in Home-Manager, choose NixOS
#
# full Home-Manager Options available for perusal at: https://nix-community.github.io/home-manager/options.html
#
# a searchable list of Home-Manager Options is avilable at: https://mipmip.github.io/home-manager-option-search/
{
  home-manager.users.${userName} = {


    ###################################
    # Home-Manager Optimised Programs #
    ###################################
    programs = {
      # NOTE you are welcome to use a different shell than BASH, however it is intimately integrated with NixOS as part of its _Standard Environment_ for building packages so if you change the shell, be aware things may behave oddly. To ensure Cyvizen is as robust as possible, BASH as part of Cyvizen
      bash = {
        shellAliases = {
          rg = "rga";
        };
        initExtra = ''
          export PATH="/etc/nixos/bin:$PATH"
        '';
        sessionVariables = {
          TERMINAL = "kitty";
          FZF_DEFAULT_COMMAND = "rg --hidden --files | fzf";
        };
      };
    };


    ############
    # SERVICES #
    ############
    services = {
      devilspie2.config = ''
      '';
    };


    ############################
    # XDG / FreeDesktop Config #
    ############################
    xdg = {
      # NOTE additional custom `home` directories can be addedd here for your Cyvizen
      # this directory *must* also be added to `cyvizen.saveTo.<relevant_location>` for data to be saved
      userDirs.extraConfig = {
        # XDG_MISC_DIR = "${config.home.homeDirectory}/Misc";
      };
      # NOTE if you wish to automatically start applications on login, place them here following the pattern of the example below
      configFile = {
        # "autostart/signal.desktop".source = builtins.storePath "${pkgs.signal-desktop}/share/applications/signal.desktop";
      };
      dataFile = { };
    };
  };
}
