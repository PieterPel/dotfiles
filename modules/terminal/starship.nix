{
  flake.modules.homeManager.starship = { config, lib, ... }:
    let
      cfg = config.modules.terminal.starship;
      firstColor = "#741D83";
    in
    {
      options.modules.terminal.starship = {
        enable = lib.mkEnableOption "Enable Starship configuration.";
      };

      config = lib.mkIf cfg.enable {
        programs.starship = {
          enable = true;
          settings = {
            # Left format
            # format = "$os$all";
            format = "[](${firstColor})$os$directory[](${firstColor}) $all";

            # Right format
            right_format = "$username$hostname$battery$time";

            # General
            command_timeout = 1300;
            scan_timeout = 50;
            character = {
              success_symbol = "[](bold green)";
              error_symbol = "[✗](bold red)";
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

            # Hide redundant package.json version noise
            package = {
              disabled = true;
            };

            # Remove Google Cloud info from prompt
            gcloud = {
              disabled = true;
            };

            # Keep bun indicator without printing the runtime version number
            bun = {
              format = "via [$symbol]($style)";
            };

            # Module specific
            directory = {
              style = "bg:${firstColor}";
              read_only_style = "bg:${firstColor}";
              format = "[$path]($style)[$read_only]($read_only_style)";
              truncate_to_repo = false;
              fish_style_pwd_dir_length = 1;
              read_only = "  ";
              use_os_path_sep = false;
              home_symbol = "~";
            };

            battery = {
              format = "[$symbol $percentage]($style) ";
              empty_symbol = "🪫";
              charging_symbol = "🔋";
              full_symbol = "🔋";
            };

            time.disabled = false;
            username.disabled = false;
            hostname.disabled = false;
            git_branch.style = "bold orange";

            os = {
              disabled = false;
              style = "bg:${firstColor}";
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
      };
    };
}
