{
  config,
  lib,
  pkgs,
  self,
  ...
}: {
  imports = [
    ./home.nix
    ./secrets.nix
    self.inputs.nixos-hardware.nixosModules.raspberry-pi-4
  ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
      fsType = "ext4";
    };

    "/mnt/Media" = let
      fsType = "cifs";
      options = [
        "gid=100"
        "guest"
        "nofail"
        "uid=${toString config.users.users.aly.uid}"
        "x-systemd.after=network.target"
        "x-systemd.after=tailscaled.service"
        "x-systemd.automount"
        "x-systemd.device-timeout=5s"
        "x-systemd.idle-timeout=60"
        "x-systemd.mount-timeout=5s"
      ];
    in {
      inherit options fsType;
      device = "//mauville/Media";
    };
  };

  hardware.enableRedistributableFirmware = true;
  i18n.defaultLocale = "en_US.UTF-8";

  environment = {
    systemPackages = with pkgs; [
      (inxi.override {withRecommends = true;})
      curl
      git
      helix
      htop
      nodePackages.nodejs
      python3
      wget
    ];

    variables.FLAKE = lib.mkDefault "github:alyraffauf/roxanne";
  };

  networking = {
    firewall = {
      allowedUDPPorts = [config.services.tailscale.port];
      trustedInterfaces = [config.services.tailscale.interfaceName];
    };

    hostName = "roxanne";

    networkmanager = {
      enable = true;
      wifi.powersave = false;
    };

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
        "https://roxanne.cachix.org"
      ];

      trusted-public-keys = [
        "alyraffauf.cachix.org-1:GQVrRGfjTtkPGS8M6y7Ik0z4zLt77O0N25ynv2gWzDM="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "roxanne.cachix.org-1:rRG7AnQksCGIOg/ZL4XodghHOnKUiOG3AImyNljxWwI="
      ];

      trusted-users = ["@wheel"];
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  programs = {
    dconf.enable = true; # Needed for home-manager

    direnv = {
      enable = true;
      nix-direnv.enable = true;
      silent = true;
    };

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    mtr.enable = true;
    nh.enable = true;
    nix-ld.enable = true;
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

    journald.extraConfig = ''
      # Store logs in RAM
      Compress=yes
      Storage=volatile
      SystemMaxUse=50M
    '';

    openssh = {
      enable = true;
      openFirewall = true;
      settings.PasswordAuthentication = false;
    };

    restic.backups = let
      defaults = {
        inhibitsSleep = true;
        initialize = true;
        passwordFile = config.age.secrets.restic-passwd.path;

        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 4"
          "--keep-monthly 6"
          "--compression max"
        ];

        rcloneConfigFile = config.age.secrets.rclone-b2.path;

        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
          RandomizedDelaySec = "1h";
        };
      };
    in {
      uptime-kuma =
        defaults
        // {
          backupCleanupCommand = ''
            ${pkgs.systemd}/bin/systemctl start uptime-kuma
          '';

          backupPrepareCommand = ''
            ${pkgs.systemd}/bin/systemctl stop uptime-kuma
          '';

          paths = ["/var/lib/uptime-kuma"];
          repository = "rclone:b2:aly-backups/${config.networking.hostName}/uptime-kuma";
        };
    };

    tailscale = {
      enable = true;
      authKeyFile = config.age.secrets.tailscaleAuthKey.path;
      openFirewall = true;
    };

    uptime-kuma = {
      enable = true;
      appriseSupport = true;
      settings.HOST = "0.0.0.0";
    };
  };

  system = {
    autoUpgrade = {
      enable = true;
      allowReboot = lib.mkDefault true;
      dates = "04:00";
      flags = ["--accept-flake-config"];
      flake = config.environment.variables.FLAKE;
      operation = lib.mkDefault "switch";
      persistent = true;
      randomizedDelaySec = "60min";

      rebootWindow = {
        lower = "04:00";
        upper = "06:00";
      };
    };

    stateVersion = "25.05";
  };

  systemd.oomd = {
    enable = true;
    enableRootSlice = true;
    enableSystemSlice = true;
    enableUserSlices = true;
  };

  time.timeZone = "America/New_York";

  users.users.aly = {
    description = "Aly Raffauf";

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

    hashedPassword = "$y$j9T$i6ZHLbNl.we5t2xmheZYR1$LnzZu.PzTPWG15L/WgfL.9KGklgcMLoozIH9aTZgi84";
    isNormalUser = true;

    openssh.authorizedKeys.keyFiles =
      lib.map (file: "${self.inputs.secrets}/publicKeys/${file}")
      (lib.filter (file: lib.hasPrefix "aly_" file)
        (builtins.attrNames (builtins.readDir "${self.inputs.secrets}/publicKeys")));
  };

  zramSwap = {
    enable = lib.mkDefault true;
    algorithm = lib.mkDefault "zstd";
    priority = lib.mkDefault 100;
  };
}
