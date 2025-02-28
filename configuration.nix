{
  lib,
  pkgs,
  ...
}: {
  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
    fsType = "ext4";
  };

  i18n.defaultLocale = "en_US.UTF-8";

  environment = {
    systemPackages = with pkgs; [
      git
      htop
      (inxi.override {withRecommends = true;})
      python3
    ];

    variables.FLAKE = lib.mkDefault "github:alyraffauf/roxanne";
  };

  networking = {
    hostName = "roxanne";
    networkmanager.enable = true;
    nftables.enable = true;
  };

  nix = {
    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
      persistent = true;
      randomizedDelaySec = "60min";
    };

    # Run GC when there is less than 1GiB left.
    extraOptions = ''
      min-free = ${toString (1 * 1024 * 1024 * 1024)}   # 1 GiB
      max-free = ${toString (5 * 1024 * 1024 * 1024)}   # 5 GiB
    '';

    optimise = {
      automatic = true;
      persistent = true;
      randomizedDelaySec = "60min";
    };

    settings = {
      experimental-features = ["nix-command" "flakes"];

      substituters = [
        "https://alyraffauf.cachix.org"
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
      ];

      trusted-public-keys = [
        "alyraffauf.cachix.org-1:GQVrRGfjTtkPGS8M6y7Ik0z4zLt77O0N25ynv2gWzDM="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];

      trusted-users = ["@wheel"];
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  programs = {
    dconf.enable = true; # Needed for home-manager

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    mtr.enable = true;
    nh.enable = true;
  };

  security = {
    polkit.enable = true;
    rtkit.enable = true;
  };

  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;

      publish = {
        enable = true;
        addresses = true;
        userServices = true;
        workstation = true;
      };
    };

    openssh = {
      enable = true;
      openFirewall = true;
      # settings.PasswordAuthentication = false;
    };
  };

  system.stateVersion = "25.05";
  time.timeZone = "America/New_York";

  users.users.aly = {
    isNormalUser = true;

    extraGroups = [
      "dialout"
      "docker"
      "libvirtd"
      "lp"
      "networkmanager"
      "plugdev"
      "scanner"
      "transmission"
      "video"
      "wheel"
    ];
  };
}
