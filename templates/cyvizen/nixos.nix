args@{ config, lib, pkgs, userName, ... }:
# NOTE Cyvizen has pre-configured >95% of any NixOS configuration you would need for a stable system, configuration in this file is intended for additional functionality that is not bundled into Cyvizen.
# If there is a conflict between functionality you are trying to enable and Cyvizen we *strongly* suggest you seek advice from support by raising a support ticket
with lib;
{
  ############################
  # NixOS Optimised Programs #
  ############################
  # NOTE a list of programs NixOS has extended / custom support for can be found at https://search.nixos.org/options?channel=22.11&from=0&size=50&sort=relevance&type=packages&query=programs.
  programs = {
    evolution.plugins = [ ];
  };


  # NOTE DO NOT enable services.getty.autoLoginUser this is a massive security breach as anyone pressing ctrl+alt+<F2> will be able to access a terminal with your Cyvizen logged in (even from the login screen)
  services = {
    gnome = {
      gnome-online-accounts.enable = false;
      gnome-online-miners.enable = false;
    };
    xserver = {
      # NOTE should you use a different keyboard layout it can be applied system-wide as below
      # xkbVariant = "colemak";
    };
  };

  ######################################
  # (Optional) Printer Specific Config #
  ######################################
  # hardware.printers = {
  # 	ensureDefaultPrinter = "multifunction";
  # 	ensurePrinters = [
  # 		{
  # 			name = "multifunction";
  # 			deviceUri = "ipp://home.multi/ipp";
  # 			model = "everywhere";
  # 			description = "";
  # 			location = "REarth Shed";
  # 		}
  # 	];
  # };
  # services.printing.drivers = with pkgs; [
  # 	INSERT_DRIVER
  # 	INSERT_DRIVER_OPTIONAL
  # ]:

  #################################
  # (Optional Additional Secrets) #
  #################################
}
