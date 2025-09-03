{ config
, pkgs
, lib
, ...
}:

let
  cfg = config.modules.programs.vscodium;
in
{
  options.modules.programs.vscodium = {
    enable = lib.mkEnableOption "Enable VSCode/VSCodium configuration.";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    packages = with pkgs; [
      vscodium
    ];

    programs.vscode = {
      enable = true;
      package = pkgs.vscode.fhs;
      profiles.pieterp.extensions =
        with pkgs.vscode-extensions;
        [
          # General
          usernamehw.errorlens
          tomoki1207.pdf
          tal7aouy.icons
          github.copilot
          github.copilot-chat
          eamodio.gitlens
          mhutchie.git-graph
          aaron-bond.better-comments

          # Python
          ms-python.python
          ms-python.vscode-pylance
          charliermarsh.ruff
          ms-python.debugpy
          ms-toolsai.jupyter

          # Rust
          rust-lang.rust-analyzer

          # Nix
          jnoortheen.nix-ide

          # Haskell
          haskell.haskell

          # Direnv
          mkhl.direnv

          # Toml
          tamasfe.even-better-toml

          # Yaml
          redhat.vscode-yaml

          #.env
          irongeek.vscode-env

          # Markdown
          dendron.dendron-markdown-preview-enhanced
          bierner.markdown-mermaid

          # Themes
          hiukky.flate
          dracula-theme.theme-dracula
          emroussel.atomize-atom-one-dark-theme
          enkia.tokyo-night
          viktorqvarfordt.vscode-pitch-black-theme
        ]
        ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          {
            name = "pyrefly";
            publisher = "meta";
            version = "0.16.2";
            sha256 = "z6JNY8DWWyn8J/6HG2WH76Yrv+saqxzJ35RAnUx8N2c=";
          }
        ];
    };
  };
}
