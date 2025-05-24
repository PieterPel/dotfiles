{config, pkgs, ...}:

{
  home.packages = with pkgs; [
    vscodium
  ];

  programs.vscode = {
    enable = false;
    package = pkgs.vscodium;
    #package = pkgs.vscode-fhs;
    profiles.pieterp.extensions = with pkgs.vscode-extensions; [
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

    ];
  };
}
