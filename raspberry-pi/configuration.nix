# To build, use:
# nix-build nixos -I nixos-config=nixos/modules/installer/cd-dvd/sd-image-raspberrypi.nix -A config.system.build.sdImage
{ config, lib, pkgs, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/installer/scan/detected.nix>
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    <nixpkgs/nixos/modules/profiles/clone-config.nix>
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
  ];

  disabledModules = [
    <nixpkgs/nixos/modules/profiles/base.nix>
    <nixpkgs/nixos/modules/tasks/auto-upgrade.nix>
    <nixpkgs/nixos/modules/profiles/installation-device.nix>
    <nixpkgs/nixos/modules/installer/tools/tools.nix>
  ];

  # if you have a Raspberry Pi 2 or 3, pick this:
  boot.kernelPackages = pkgs.linuxPackages_latest;
#   boot.kernelPackages = pkgs.linuxPackages_rpi1;


  nixpkgs = {
    overlays = [ (self: super: {
      libnl = super.libnl.override { pythonSupport = false; };
      gobject-introspection = super.gobject-introspection.override {
        x11Support = false;
      };
      dbus = super.dbus.override { x11Support = false; };
    }) ];
    config = { };
    crossSystem = lib.systems.elaborate lib.systems.examples.raspberryPi;
    localSystem = { system = "x86_64-darwin"; };
  };


  # Things that don't compile or aren't needed
  fonts.fontconfig.enable = false;
  documentation.enable = false;
  security.polkit.enable = false;
  boot.supportedFilesystems = [ "vfat" ];
  services.udisks2.enable = false;
  xdg.mime.enable = false;


  # A bunch of boot parameters needed for optimal runtime on RPi 3b+
  boot.kernelParams = ["cma=256M"];
  boot.loader.raspberryPi.enable = true;
  boot.loader.raspberryPi.version = 3;
  boot.loader.raspberryPi.uboot.enable = true;
  boot.loader.raspberryPi.firmwareConfig = ''
    gpu_mem=256
  '';

  environment.systemPackages = with pkgs; [
    raspberrypi-tools
    pkgs.tmux
    pkgs.lynx
  ];

  # File systems configuration for using the installer's partition layout
  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-label/NIXOS_BOOT";
      fsType = "vfat";
    };
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  };

  # Preserve space by sacrificing documentation and history
  services.nixosManual.enable = false;
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 30d";
  boot.cleanTmpDir = true;

  # Configure basic SSH access
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";

  # Use 2GB of additional swap memory in order to not run out of memory
  # when installing lots of things while running other things at the same time.
  swapDevices = [ { device = "/swapfile"; size = 2048; } ];

  networking.wireless = {
    enable = true;
    networks = {
      honors = { };
      Bilby = { };
    };
  };


}
