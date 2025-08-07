{ ...
}:
{
  # Enable password authentication for SSHing into the RPi
  services.openssh.settings.passwordAuthentication = true;

  # Make users immutable
  users.mutableUsers = false;

}
