{
  flake.modules.darwin.docker-mcp = { config, lib, pkgs, ... }:
    let
      cfg = config.modules.virtualization.docker-mcp;

      # Docker Desktop admin settings for MCP Toolkit
      adminSettings = {
        enableDockerMCPToolkit = true;
        allowBetaFeatures = true;
        # Optional: Enable Docker AI features
        enableDockerAI = true;
      };

      adminSettingsJson = pkgs.writeText "admin-settings.json"
        (builtins.toJSON adminSettings);

    in
    {
      options.modules.virtualization.docker-mcp = {
        enable = lib.mkEnableOption "Enable Docker MCP Toolkit configuration";

        enableDynamicTools = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable dynamic MCP tools (mcp-find, mcp-add, etc.)";
        };
      };

      config = lib.mkIf cfg.enable {
        # Ensure Docker Desktop is installed via homebrew
        homebrew.casks = [ "docker" ];

        # Install the admin-settings.json file (runs as root)
        system.activationScripts.dockerMcpConfig.text = ''
          # Create Docker Desktop config directory if it doesn't exist
          mkdir -p "/Library/Application Support/com.docker.docker"

          # Copy admin settings
          cp -f "${adminSettingsJson}" "/Library/Application Support/com.docker.docker/admin-settings.json"
          chmod 644 "/Library/Application Support/com.docker.docker/admin-settings.json"

          echo "Docker MCP Toolkit admin settings configured"
          echo "Please restart Docker Desktop for changes to take effect"
        '';

        # Optional: Add docker mcp CLI commands to manage dynamic tools
        system.activationScripts.dockerMcpDynamicTools = lib.mkIf (!cfg.enableDynamicTools) {
          text = ''
            # Disable dynamic tools if user preference is set to false
            if command -v docker &> /dev/null; then
              docker mcp feature disable dynamic-tools 2>/dev/null || true
            fi
          '';
        };
      };
    };
}
