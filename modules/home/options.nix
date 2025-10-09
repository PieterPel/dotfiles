{
  lib,
  ...
}:
{
  flake.modules.homeManager.options = {
    options = {
      browser = lib.mkOption {
        type = lib.types.str;
        default = "brave";
        description = "Default browser";
      };
      explorer = lib.mkOption {
        type = lib.types.str;
        default = "thunar";
        description = "Default file explorer";
      };
      terminal = lib.mkOption {
        type = lib.types.str;
        default = "kitty";
        description = "Default terminal";
      };
      editor = lib.mkOption {
        type = lib.types.str;
        default = "nvim";
        description = "Default editor";
      };
      stateVersion = lib.mkOption {
        type = lib.types.str;
        default = "24.11";
        description = "Default stateVersion";
      };
    };
  };

  flake.modules.standaloneHomeManager.options = {
    options = {
      username = lib.mkOption {
        type = lib.types.str;
        description = "The username of the user";
      };
    };
  };
}