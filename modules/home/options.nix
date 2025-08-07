{ lib, ... }:

{
  options.enableDesktopApps = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable desktop applications";
  };

  options.browser = lib.mkOption {
    type = lib.types.string;
    default = "brave";
    description = "Default browser";
  };

  options.explorer = lib.mkOption {
    type = lib.types.string;
    default = "thunar";
    description = "Default file explorer";
  };

  options.terminal = lib.mkOption {
    type = lib.types.string;
    default = "kitty";
    description = "Default terminal";
  };

  options.editor = lib.mkOption {
    type = lib.types.string;
    default = "nvim";
    description = "Default editor";
  };

  options.stateVersion = lib.mkOption {
    type = lib.types.string;
    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    default = "24.11"; # Please read the comment before changing.
    description = "Default stateVersion";
  };

}
