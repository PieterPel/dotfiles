{ ... }:
{
  programs.starship = {
    enable = true;
    settings = {

      # Left format
      format = "$os$all";

      # Right format
      right_format = "$username$hostname$time";

      # General
      command_timeout = 1300;
      scan_timeout = 50;
      character = {
        success_symbol = "[](bold green) ";
        error_symbol = "[✗](bold red) ";
      };

      # language specific
      nix_shell = {
        disabled = false;
        symbol = "❄️ ";
        format = "via [$symbol$state]($style) ";
      };
      python.symbol = " ";
      rust.symbol = "󱘗 ";
      c.symbol = " ";
      cpp.symbol = " ";
      gleam.symbol = "★";

      # Module specific
      directory = {
        style = "bold purple";
        truncate_to_repo = false;
        fish_style_pwd_dir_length = 1;
        read_only = "🔒";
        use_os_path_sep = false;
        home_symbol = "~";
      };
      time.disabled = false;
      username.disabled = false;
      hostname.disabled = false;
      git_branch.style = "bold orange";
      os = {
        disabled = false;
        symbols = {
          Alpaquita = " ";
          Alpine = " ";
          AlmaLinux = " ";
          Amazon = " ";
          Android = " ";
          Arch = " ";
          Artix = " ";
          CachyOS = " ";
          CentOS = " ";
          Debian = " ";
          DragonFly = " ";
          Emscripten = " ";
          EndeavourOS = " ";
          Fedora = " ";
          FreeBSD = " ";
          Garuda = "󰛓 ";
          Gentoo = " ";
          HardenedBSD = "󰞌 ";
          Illumos = "󰈸 ";
          Kali = " ";
          Linux = " ";
          Mabox = " ";
          Macos = " ";
          Manjaro = " ";
          Mariner = " ";
          MidnightBSD = " ";
          Mint = " ";
          NetBSD = " ";
          NixOS = " ";
          Nobara = " ";
          OpenBSD = "󰈺 ";
          openSUSE = " ";
          OracleLinux = "󰌷 ";
          Pop = " ";
          Raspbian = " ";
          Redhat = " ";
          RedHatEnterprise = " ";
          RockyLinux = " ";
          Redox = "󰀘 ";
          Solus = "󰠳 ";
          SUSE = " ";
          Ubuntu = " ";
          Unknown = " ";
          Void = " ";
          Windows = "󰍲 ";
        };
      };
    };
  };

}
