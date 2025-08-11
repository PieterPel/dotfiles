{ ... }:

{
  minimal = true;

  # Enable password authentication for SSHing into the RPi
  services.openssh.settings.passwordAuthentication = true;

  # Make users immutable
  users.mutableUsers = false;

  # Enable modules conditionally based on `minimal`
  modules.core = {
    configuration.enable = true;
    nix.enable = true;
    sops.enable = true;
  };

  modules.nixos = {
    internationalization.enable = true;
    networking.enable = true;
    sound.enable = true;
    updating.enable = true;
    virtualization.enable = true;
  };
}
