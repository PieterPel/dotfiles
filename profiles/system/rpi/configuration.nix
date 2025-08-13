{ ... }:

{
  minimal = true;

  # Enable password authentication for SSHing into the RPi
  services.openssh = {
    settings.PasswordAuthentication = true; # TODO: put to false
    settings.PermitRootLogin = "no";
  };

  # Make users immutable
  # TODO: implement
  # users.mutableUsers = false;

  # Enable sudo without password
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false; # members of wheel group don't need password
  };

  # Enable modules conditionally based on `minimal`
  modules.core = {
    configuration.enable = true;
    nix.enable = true;
    sops.enable = true;
  };

  modules.nixos = {
    internationalization.enable = true;
    networking.enable = true;
    updating.enable = true;
    virtualization.enable = true;
  };
}
