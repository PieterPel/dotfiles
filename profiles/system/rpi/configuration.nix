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

  modules.system.configuration.enable = true;
  modules.package-management.nix.enable = true;
  modules.security.sops.enable = true;

  modules.nixos = {
    configuration.enable = true;
    internationalization.enable = true;
    updating.enable = true;
    virtualization.enable = true;
  };

  modules.programs = {
    starship.enable = true;
  };
}
