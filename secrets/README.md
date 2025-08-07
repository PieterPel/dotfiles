Okay, you're reading this. This probably means that you haven't updated your secrets
in a while. Here comes the recap on how to do it:


* Get public key of host: `nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'`
* Regenerate encrypted file: `$ nix-shell -p sops --run "sops updatekeys secrets/example.yaml"`
