  { config, pkgs, ... }:

{
  
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  imports = [ ./hardware-configuration.nix ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [ "nvidia-drm.modeset=1" "nvidia.NVreg_PreserveVideoMemoryAllocations=1" "i8042.reset" "i8042.nomux" ];

  services.fstrim.enable = true;

  # Networking
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  systemd.services.NetworkManager-wait-online.enable = false;
  networking.wireguard.enable = true;
  
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 22000 6600 7070 4444 4447 7656 7657 9091];  # SSH,  , MPD, i2pd, TOR, transmission
    allowedUDPPorts = [ 22000 21027 51820 51413]; # transmisison
  };

  # SSH
  services.openssh = {
    enable = true;
    permitRootLogin = "no";
    passwordAuthentication = true;
  };

  # автоматическое обнаружение ipv4 узла по ЮЗБ-езернет адаптеру
  networking.networkmanager.ensureProfiles.profiles = {
    nettop-share = {
      connection = {
        id = "nettop-share";
        type = "ethernet";
        interface-name = "enp0s20f0u4"; # Твой USB-адаптер
        autoconnect = true;
      };
      ipv4 = {
        method = "shared"; # Это и включает DHCP-сервер + NAT
      };
      ipv6 = {
        method = "ignore";
      };
    };
  };


  # 3. Настраиваем dnscrypt-proxy на порт 5353 (не 53!)
  services.dnscrypt-proxy2 = {
    enable = false;
    
    settings = {
      # Используем порт 5353 (Avahi теперь на 5354)
      listen_addresses = [ "127.0.0.1:5353" ];
      
      # Простые серверы которые точно работают
      server_names = [ "cloudflare" "quad9" ];
      
      # Логи для отладки
      log_level = 2;
      log_files_max_size = 1;
      
      # Базовые настройки
      ipv6_servers = true;
      require_dnssec = false;  # пока false
      require_nolog = true;
      require_nofilter = false;
      
      # Кэширование
      cache = true;
      cache_size = 4096;
    };
  };
  
  # 4. Указываем системе использовать наш dnscrypt-proxy
  #networking.nameservers = [ "127.0.0.1:5353" ];
  #networking.resolvconf.enable = false;
  
  # 5. Принудительно прописываем resolv.conf
  #environment.etc."resolv.conf".text = ''
  #  nameserver 127.0.0.1
  #  port 5353
  #  options edns0
  #'';
  
  # 6. Зависимости - гарантируем что Avahi стартанет первым
  #systemd.services.dnscrypt-proxy2 = {
  #  after = [ "avahi-daemon.service" ];
  #  requires = [ "avahi-daemon.service" ];
  #};



  # Включить I2PD
  services.i2pd = {
    enable = true;
   
    proto = {
      i2cp.enable = true;
      bob.enable = false;
    };
  };

  # TOR
  services.tor.enable = true;
  services.tor.client.enable = true;

  # Time & Locale
  time.timeZone = "Europe/Moscow";
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


  # Вместо GDM попробуй:
  #services.displayManager.gmd.enable = true;
  #services.displayManager.gdm.wayland.enable = true;

  # X11 & Display
  services.xserver = {
    layout = "us,ru";
    xkbVariant = "";
    xkbOptions = "grp:win_space_toggle";
    enable = true;
    videoDrivers = ["nvidia"];
    libinput.enable = true;
    
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  services.displayManager.defaultSession = "hyprland";
  services.udev.packages = [ pkgs.brightnessctl ];

  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # ZSH
  programs.zsh = {
    enable = true;
    enableBashCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    
    ohMyZsh = {
      enable = true;
      plugins = [ "git" "systemd" "sudo" ];
    };
    
    promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
  };

  # VPN
  # Включение OpenVPN
  services.openvpn.servers = {
    demee-thinkpad = {
      autoStart = false;  # или true, если нужно запускать при старте системы
      config = "config /etc/openvpn/demee-thinkpad.ovpn";
      up = "systemctl restart network-online.target";  # опционально
    };
  };

  # Копирование конфига VPN
  environment.etc."openvpn/demee-thinkpad.ovpn" = {
    source = /home/lola/.vpn/demee-thinkpad.ovpn;
    mode = "0600";  # только для root
  };

  # Если нужно управлять через systemd
  #systemd.services."openvpn-demee-thinkpad" = {
  #  description = "OpenVPN демон для demee-thinkpad";
  #  wants = ["network-online.target"];
  #  after = ["network-online.target"];
  #  serviceConfig = {
  #    Type = "notify";
  #    Restart = "on-failure";
  #  };
  #};

  #services.openvpn.servers = {
  #  demee-thinkpad = {
  #    config = '' config /etc/openvpn/demee-thinkpad.ovpn '';
  #    autoStart = false;
  #  };
  #};
  
  #environment.etc = {
  #  "openvpn/demee-thinkpad.ovpn".source = /home/lola/.vpn/demee-thinkpad.ovpn;
  #};

  programs.hyprland.enable = true;

  security.polkit.enable = true;
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  # Graphics / OpenGL
  hardware.graphics = { # В новых версиях NixOS это называется hardware.graphics
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
      nvidia-vaapi-driver # Добавляем для Nvidia
    ];
  };

# Nvidia специфичные настройки для Wayland
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false; # Можно поставить true, если ноут
    open = false; # Ставим true, если видеокарта серии 16xx или новее (Turing+)
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };


# Добавляем переменные окружения для Hyprland + Nvidia
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    XDG_SESSION_TYPE = "wayland";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1"; # Чтобы мышка не исчезала
    NIXOS_OZONE_WL = "1"; # Чтобы Chromium/Electron приложения работали в Wayland
  };


  # Graphics
#  hardware.opengl = {  # Оставляем как было, если hardware.graphics не работает
#    enable = true;
#    driSupport32Bit = true;
#    extraPackages = with pkgs; [
#      intel-media-driver
#      vaapiIntel
#      vaapiVdpau
#      libvdpau-va-gl
#    ];
#  };

  #hardware.nvidia = {
  #  modesetting.enable = true;
  #  package = config.boot.kernelPackages.nvidiaPackages.stable;
  #};

  # Printing
  services.printing.enable = true;

  # Flatpak
  services.flatpak.enable = true;

  # Audio
  #services.pulseaudio = {
  #  enable = false;
  #  support32Bit = true;  # Для 32-битных игр
  #};
  
  security.rtkit.enable = true;
  services.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Steam hardware
  hardware.steam-hardware.enable = true;

  # User
  users.users.lola = {
    isNormalUser = true;
    description = "lola";
    extraGroups = [ "networkmanager" "wheel" "audio" "pipewire" "video"];
    shell = pkgs.zsh;
  };


  # Firefox
  programs.firefox = {
    enable = true;
  };


# Разрешаем несвободный софт и дырявый SSL для саблайма
  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "openssl-1.1.1w"
    ];
  };

  # Gnome extensions autostart
  programs.dconf.enable = true;
  
  environment.etc."xdg/autostart/pop-shell.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Pop Shell
    Exec=gnome-extensions enable pop-shell@system76.com
    Hidden=false
    NoDisplay=false
    X-GNOME-Autostart-enabled=true
  '';

  # Fonts
  fonts.packages = with pkgs; [
    fira-code
    jetbrains-mono
    cascadia-code
  ];


  # Transmission
  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
    openRPCPort = true; #Open firewall for RPC
    
    settings = {
      peer-port = 51413;
      port-forwarding-enabled = true;
      encryption = 1;
      rpc-port = 9091;
      rpc-bind-address = "0.0.0.0"; # Доступ со всех интерфейсов
      rpc-whitelist-enabled = false; # Отключаем белый список      
    };
  };

  # Syncthing
  services.syncthing = {
    enable = true;
    user = "lola";
    dataDir = "/home/lola/Sync";
    configDir = "/home/lola/.config/syncthing";
    guiAddress = "127.0.0.1:8384";
    openDefaultPorts = true;
  };


  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Для работы с буфером обмена
 # services.gpg-agent = {
 #   enable = true;
 #   pinentryFlavor = "curses"; # или "qt" для GUI
 # };

  # Kernel modules
  #boot.extraModulePackages = with config.boot.kernelPackages; [ ];
  boot.initrd.kernelModules = [ "hid_multitouch" "i2c_hid_acpi" ];
  #boot.kernelParams = [ "i8042.reset" "i8042.nomux" ];

  # System packages (без дубликатов)
  environment.systemPackages = with pkgs; [


    polkit_gnome
    xdg-desktop-portal-hyprland
    hyprpaper
    swww
    networkmanagerapplet
    pavucontrol
    wl-clipboard

    # nix system
    direnv
    nix-direnv
    
    
    # VPN & Networking
    wireguard-tools
    nmap
    inetutils
    aircrack-ng

    onionshare
    tor
    torsocks

    i2pd
    proxychains    
    dnscrypt-proxy2


    bpftrace
    bcc
    linuxPackages.perf

    #Mount
    sshfs

    # XMPP
    profanity
    poezio
    dino
    freetalk
    xmppc
   # matsuri
    

    #torrent
    transmission
    tremc
    #transmission-daemon
    libtransmission_4 
    #transmission-remote-cli
    #stig
    
    # Полезные скрипты
    (writeShellScriptBin "i2p-check" ''
      echo "Проверка I2PD:"
      echo "1. Сервис: $(systemctl is-active i2pd)"
      echo "2. Веб-консоль: http://127.0.0.1:7070"
      echo "3. HTTP прокси: 127.0.0.1:4444"
      echo "4. SOCKS прокси: 127.0.0.1:4447"
      echo ""
      echo "Тест через HTTP прокси:"
      curl --proxy http://127.0.0.1:4444 http://stats.i2p/cgi-bin/newstats.rda 2>/dev/null | head -5
    '')

    # Input
    libinput
    xorg.xinput
    xorg.xev
    
    # Apps
    telegram-desktop
    waybar
    rofi-wayland
    
    # Terminal
    kitty
    alacritty

    xclip
    
    # Browser
    google-chrome
    librewolf
    
    # Utils & productivity  
    mc
    calcurse
    taskwarrior3
    htop
    btop
    iftop
    nethogs
    vnstat
    wavemon
    pass
    bat
    ripgrep
    fd
    fzf
    lsof
    psmisc


    termshark
    tcpflow
    ngrep
    dnsenum
    

    theharvester
    sherlock
    
    scrcpy
    android-tools
    usbutils

    # secret management
    pass
    gnupg
    gpg-tui
    pinentry

    # file manager
    yazi
    ffmpegthumbnailer
    unzip
    jq
    poppler
    fd
    fzf    

    # DE & UI & WM
    bibata-cursors
    qt5.qtwayland
    qt6.qtwayland

    grim
    slurp

    #Customize
    nwg-look

    #graphics
    blender
    
    # Audio & Media
    ncmpcpp
    mpc
    mpd
    ffmpeg
    cava
    mpv
    plugdata
    puredata
    supercollider
    imagemagick

    # DAW & Sound Design
    #tracktion-waveform-free
    ardour
    qtractor
    lmms
    zrythm
    renoise
    
    #renoise
    #cecilia5
    #sneedacity    

    # SYNTHS
    vital
    surge
    odin2
    dexed
    #tal-noizemaker
    helm

    # FX
    dragonfly-reverb
    lsp-plugins
    #distrho
    calf
    x42-plugins
    zam-plugins
   

    # audio utils
    carla
    #cadence
    fftw
    libsndfile
    jack2

    
    # Editors & Dev
    vscode
    sublime4
    helix
    neovim
    zed-editor
    rust-analyzer
    clang-tools
    cmake
    pkg-config
    git
    github-cli
    gnumake
    gcc
    rustup
    python3
    tree-sitter



    # LLM & AI
    aider-chat
    aichat

    # Drawing editor
    pinta
    
    # Encryption
    age
    
    # Knowledge
    obsidian
    
    # ZSH тема
    zsh-powerlevel10k
    
    # Containers
    docker
    docker-compose
    
    # Monitoring
    grafana
    
    # Automation
    ansible
    
    # Screen Recording
    obs-studio
    
    # Gaming
    steam-run
    steamcmd

    # games
    cataclysm-dda-git
    srb2

    vkquake
    yquake2-all-games
    quake-injector

    gzdoom
    quakespasm    
    veloren
    
    
    # Gnome Extensions (основные)
    gnomeExtensions.blur-my-shell
    gnomeExtensions.dash-to-dock
    gnomeExtensions.vitals
    gnomeExtensions.appindicator
    gnomeExtensions.caffeine
    gnomeExtensions.user-themes
    gnomeExtensions.pop-shell
    
    # Themes
    whitesur-gtk-theme
    orchis-theme
    qogir-theme
    papirus-icon-theme
    whitesur-icon-theme
    
    # radio 
    urh
    
    # usb
    #luna-usb

    # Encryption
    veracrypt
    cryptsetup
    
    # Misc
    wget
    yt-dlp
    newsboat
    w3m
    feh
    cmatrix
    neofetch
    pfetch
    fastfetch
    lldb
    
    # clients
    haxor-news
    hn-text
        
    # guilty pleasures
    #yandex-browser
    flatpak
    appimage-run
    wtf
  ];

  system.stateVersion = "25.05";
}
