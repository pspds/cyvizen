args@{ config, lib, pkgs, ... }:
{
  boot.initrd.preLVMCommands = ''
    TXT_COLOUR="\e[96m"
    HIGHLIGHT="\e[41m"
    TXT_RESET="\e[0m"
    echo -e $TXT_COLOUR"\n\nCongratulations you are now the proud owner of a "$HIGHLIGHT"Cyvizen"$TXT_RESET$TXT_COLOUR" compatible computer\n"$TXT_RESET
    echo -e $TXT_COLOUR"You're "$HIGHLIGHT"Cyvive Scorched Earth"$TXT_RESET$TXT_COLOUR" way of life is getting stronger!\n"
    echo -e $TXT_COLOUR"Type the word "$HIGHLIGHT"cyvizen"$TXT_RESET$TXT_COLOUR" and press the <enter> key to begin"$TXT_RESET
  '';

  users.users.root.initialHashedPassword = "";
  users.users.root.shell = pkgs.bashInteractive;
  users.users.root.packages = pkgs.callPackage (../pkgs) args;
  programs.bash.loginShellInit = ''
    cd /etc/nixos/bin
    ./_start.js machine oem --wifi

    # NOTE wifi always auto disconnects after init/loss of setup shell
    check_wifi_connection() {
      wpa_status=$(wpa_cli status | grep wpa_state | cut -d"=" -f2)
      return $(test "$wpa_status" = "COMPLETED")
    }

    wpa_cli reconnect
    while ! check_wifi_connection; do
      sec=4
      while [ $sec -ge 0 ]; do
        echo -ne "Validating WiFi Connection is stable $sec\033[0K\r"
        let "sec=sec-1"
        sleep 1
      done
    done
    wpa_cli reconnect

    sleep 2

    ./_start.js machine oem --install
  '';
  services.getty.autologinUser = "root";
  services.getty.helpLine = ''
    '';

  environment.variables.EDITOR = "micro";
  environment.shellAliases = {
    ls = "ls --color=auto";
  };

  networking.firewall.enable = false;
  services.opensnitch.enable = false;
}
