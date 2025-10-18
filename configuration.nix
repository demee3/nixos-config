# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];


  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  networking.wireguard.enable = true;

  # Enable ssh 
  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
    passwordAuthentication = true;
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 22000 ]; # Ssh
    allowedUDPPorts = [ 22000 21027 51820 ]; # Syncthing Wireguard
  };

  # Set your time zone.
  time.timeZone = "Europe/Moscow";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = ["en_US.UTF-8/UTF-8" "ru_RU.UTF-8/UTF-8"];

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ru_RU.UTF-8";
    LC_IDENTIFICATION = "ru_RU.UTF-8";
    LC_MEASUREMENT = "ru_RU.UTF-8";
    LC_MONETARY = "ru_RU.UTF-8";
    LC_NAME = "ru_RU.UTF-8";
    LC_NUMERIC = "ru_RU.UTF-8";
    LC_PAPER = "ru_RU.UTF-8";
    LC_TELEPHONE = "ru_RU.UTF-8";
    LC_TIME = "ru_RU.UTF-8";
  };
  
  # блокировка на уровне ядра
#  services.udev.extraHwdb = ''
#    # Блокируем КОНКРЕТНО устройство с названием "AT Translated Set 2 keyboard"
#    evdev:name:AT Translated Set 2 keyboard:*
#     KEYBOARD_KEY_36=ignore
#  '';


#  boot.blacklistedKernelModules = [ "atkbd" ];


  # Enable X11 window system
  services.xserver = {
    layout = "us,ru";
    xkbVariant = "";
    xkbOptions = "grp:win_space_toggle"; #Win + Space
    enable = true;
    libinput.enable = true;

  };

  programs.hyprland.enable = true;

  programs.zsh = {

    enable = true;
    enableBashCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    ohMyZsh = {
      enable = true;
      plugins = [ "git" "zsh-autosuggestions" "zsh-autocomplete" "zsh-syntax-highlighting" "systemd" "sudo" ];
      #theme = "powerlevel10k/powerlevel10k";
    };
  
  promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
  };
  
  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;


  services.openvpn.servers = {
    demee-thinkpad = {
      config = '' config /etc/openvpn/demee-thinkpad.ovpn '';
      autoStart = false;
    };
  };

  environment.etc = {
    "openvpn/demee-thinkpad.ovpn".source = /home/lola/.vpn/demee-thinkpad.ovpn;
  };


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
#  services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.lola = {
    isNormalUser = true;
    description = "lola";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # VPN
    wireguard-tools

    libinput
    xorg.xinput
    xorg.xev

    telegram-desktop
    waybar
    rofi-wayland
    kitty
    alacritty
    librewolf
    taskwarrior
    htop
    pass
    ncmpcpp
    mpd
    wget
    yt-dlp
    newsboat
    syncthing
    age
    nmap
    aircrack-ng
    onionshare
    bat
    btop
    cava
    ffmpeg
    mpv
    cmatrix
    neofetch
    # PRIVACY
    tor
    openvpn
    torsocks
    # EDITORS
    sublime
    helix
    neovim
    zed-editor
    # LSP Servers
    rust-analyzer
    clang-tools
    # TOOLS
    cmake
    pkg-config
    git
    github-cli
    gnumake
    lldb
    
    ripgrep
    fd
    fzf
    
    # dependencies
    gcc
    rustup
    python3
    tree-sitter

    #FILE SYNC
    syncthing

    #knowledge base
    obsidian

    #ZSH
    oh-my-zsh
    zsh
    zsh-autosuggestions
    zsh-autocomplete
    zsh-syntax-highlighting
    zsh-powerlevel10k # Установка темы

  ];

  
  # Syncthing system service
  services.syncthing = {
    enable = true;
    user = "lola";
    dataDir = "/home/lola/Sync";
    configDir = "/home/lola/.config/syncthing";
    
    # GUI settings
    guiAddress = "127.0.0.1:8384";
    
    # Open firewall ports
    openDefaultPorts = true;
    
    # Optional: override devices and folders
    # settings = {
    #   devices = {
    #     "device-id" = {
    #       id = "DEVICE-ID-HERE";
    #     };
    #   };
    #   folders = {
    #     "Obsidian" = {
    #       path = "/home/your-username/Obsidian";
    #       devices = [ "device-id" ];
    #     };
    #   };
    # };
  };

  boot.extraModulePackages = with config.boot.kernelPackages; [ ];
  boot.initrd.kernelModules = [ "hid_multitouch" "i2c_hid_acpi" ];

  boot.kernelParams = [ 
    "i8042.reset"
    "i8042.nomux"
  ];

  system.stateVersion = "25.05"; # Did you read the comment?

}
