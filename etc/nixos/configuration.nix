# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.initrd.luks.devices."luks-c440aa78-e867-4114-9274-0bc7329b886e".device = "/dev/disk/by-uuid/c440aa78-e867-4114-9274-0bc7329b886e";
  # Setup keyfile
  boot.initrd.secrets = {
    "/boot/crypto_keyfile.bin" = null;
  };

  boot.loader.grub.enableCryptodisk = true;

  boot.initrd.luks.devices."luks-171659c1-fc71-4e13-8269-292ee9ca597a".keyFile = "/boot/crypto_keyfile.bin";
  boot.initrd.luks.devices."luks-c440aa78-e867-4114-9274-0bc7329b886e".keyFile = "/boot/crypto_keyfile.bin";
  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Pacific/Auckland";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_NZ.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_NZ.UTF-8";
    LC_IDENTIFICATION = "en_NZ.UTF-8";
    LC_MEASUREMENT = "en_NZ.UTF-8";
    LC_MONETARY = "en_NZ.UTF-8";
    LC_NAME = "en_NZ.UTF-8";
    LC_NUMERIC = "en_NZ.UTF-8";
    LC_PAPER = "en_NZ.UTF-8";
    LC_TELEPHONE = "en_NZ.UTF-8";
    LC_TIME = "en_NZ.UTF-8";
  };

  # Enable the X11 windowing system (needed for XWayland compatibility with older apps)
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  hardware.graphics.enable = true;

  services.xserver.displayManager.lightdm = {
    enable = true;
    greeters.gtk = {
      enable = true;
      theme = {
        name = "Breeze";
        package = pkgs.kdePackages.breeze-gtk;
      };
      iconTheme = {
        name = "breeze";
        package = pkgs.kdePackages.breeze-icons;
      };
    };
  };
  
  # Enable the KDE Plasma Desktop Environment.
  services.desktopManager.plasma6.enable = true;

  # Ensure SDDM can run both X11 (KDE) and Wayland (KDE, Hyprland) sessions
  services.displayManager.sddm = {
    enable = false;
    # enableHidpi = true;
    wayland.enable = true;
    # theme = "breeze";
    # autoLogin.enable = false;
  };

  # New, generic auto-login options (set enable to false to disable auto-login)
  # Make this section very explicit
  services.displayManager.autoLogin = {
    enable = false;
    user = "";  # Explicitly empty
  };
  # Set the default session if desired (you can also choose at login screen)
  # services.displayManager.defaultSession = "hyprland"; # plasma or "hyprland"

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "nz";
    variant = "";
  };

  # Enable Hyprland system-wide
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Hint Electron apps to use Wayland (optional, helps avoid some XWayland issues)
  # environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.vensder = {
    isNormalUser = true;
    description = "vensder";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
  };
  

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    htop
    nmap
    git
    whois
    # KDE apps are handled by the 'services.desktopManager.plasma6.enable' line
    hyprland
    kitty  # Example terminal that works well in Wayland
    wofi   # Example launcher
    waybar # Example status bar
    # qt6Packages.sddm
    kdePackages.sddm
    kdePackages.sddm-kcm  
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}

