{ lib, ... }:
{
  fileSystems."/" =
    {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=2G" "mode=755" ];
      neededForBoot = true;
    };
  fileSystems."/boot" =
    {
      device = "/dev/disk/by-label/ESP";
      fsType = "vfat";
      neededForBoot = true;
    };
  fileSystems."/nix" =
    {
      device = "/dev/mapper/nix";
      fsType = "btrfs";
      options = [ "subvol=nix" "compress=zstd" "noatime" "autodefrag" ];
      neededForBoot = true;
    };
  fileSystems."/etc/nixos" =
    {
      device = "/dev/mapper/nix";
      fsType = "btrfs";
      # NOTE discard=async disabled by choice to prevent leakage of Luks volume data structure
      # https://unix.stackexchange.com/questions/226445/fstrim-the-discard-operation-is-not-supported-with-ext4-on-lvm
      options = [ "subvol=nixos" "compress=zstd" "noatime" "autodefrag" ];
      neededForBoot = true;
    };

  boot.initrd.luks.devices = {
    "nix" = {
      device = "/dev/cyvizen/nix";
      bypassWorkqueues = true;
      preLVM = false;
    };
  };

  swapDevices = lib.mkDefault [ ];

  services.btrfs.autoScrub.fileSystems = [
    "/nix"
    "/etc/nixos"
  ];
}
