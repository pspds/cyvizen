args@{ config
, lib
, userName
, ...
}:
with lib;
# NOTE this provides an ability for A -> depends on -> B race conditions to be resolved by adding a hidden multi-step.
# Worst case scenario a user would have exposure until update of Cyvizen (weekly exercise), although in reality many users customise firewall or add software sooner from initial install.
if builtins.pathExists (/home + "/${userName}/Desktop") then {
  # NOTE cyvizen root user only disabled after booting with impermance and then rebuilding configuration. This provides a stabilisation & debug phase for problematic options
  users.users.root.initialHashedPassword = "!";

  services.clamav = {
    daemon.enable = true;
    updater.enable = true;
  };

} else {

  users.users.root.initialHashedPassword = "";
}
