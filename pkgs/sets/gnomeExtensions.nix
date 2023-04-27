{ lib, pkgs, ... }:
with pkgs;
with gnomeExtensions;
[
  # taskwhisperer broken in current GNOME Shell
  advanced-alttab-window-switcher
  another-window-session-manager
  argos
  auto-select-headset
  burn-my-windows
  espresso
  fuzzy-app-search
  lock-keys
  noannoyance-2
  nothing-to-say
  pano
  remmina-search-provider
  removable-drive-menu
  replace-activities-text
  trash
  vitals
  wireguard-vpn-extension
  wireless-hid
]
