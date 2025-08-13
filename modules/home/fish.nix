{ pkgs
, lib
, config
, ...
}:

let
  cfg = config.modules.programs.fish;
  eza = lib.getExe pkgs.eza;
  nh = lib.getExe pkgs.nh;
in
{
  options.modules.programs.fish = {
    enable = lib.mkEnableOption "Enable Fish shell configuration.";
  };

  config = lib.mkIf cfg.enable {
    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting # Disable greeting
      '';

      # Define plugins
      plugins = with pkgs.fishPlugins; [
      ];
    };

    home.shellAliases = {
      # NixOS
      nos = "${nh} os switch --hostname ${config.hostname} ~/dotfiles";
      noe = "${lib.getExe pkgs.neovim} ~/dotfiles/";

      # Home-manager
      hms = "${nh} home switch ~/dotfiles/";

      # Devenv
      dev-init = "nix flake init --template github:cachix/devenv";

      # CLI dropins
      cat = lib.getExe pkgs.bat;
      curl = lib.getExe pkgs.curlie;

      # LazyGit
      lg = lib.getExe pkgs.lazygit;

      # Lazyjj
      lj = lib.getExe pkgs.lazyjj;

      # eza
      ls = "${eza} --color=always --group-directories-first --icons";
      ll = "${eza} -la --icons --octal-permissions --group-directories-first";
      l = "${eza} -bGF --header --git --color=always --group-directories-first --icons";
      llm = "${eza} -lbGd --header --git --sort=modified --color=always --group-directories-first --icons";
      la = "${eza} --long --all --group --group-directories-first";
      lx = "${eza} -lbhHigUmuSa@ --time-style=long-iso --git --color-scale --color=always --group-directories-first --icons";
      lS = "${eza} -1 --color=always --group-directories-first --icons";
      lt = "${eza} --tree --level=2 --color=always --group-directories-first --icons";
      "l." = "${eza} -a | grep -E '^\\.'";

      # fastfetch
      neofetch = lib.getExe pkgs.fastfetch;

      # Sops
      gen-age = "nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'`";

      # Git
      gs = "git status";
      ga = "git add";
    };
  };
}
