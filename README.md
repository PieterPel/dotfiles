# Pieter's NixOS & nix-darwin & Home Manager Dotfiles

This repository contains my personal NixOS and Home Manager configurations, managed as a [Nix flake](https://nixos.wiki/wiki/Flakes). 
It aims to provide a declarative, reproducible, and modular way to manage my system configurations across different machines.
A good dotfiles repo can be a lifetime project, so expect many breaking changes. 
If you decide to use this as basis for your own dotfiles I HIGHLY recommend forking it and making it your own.
The inspiration for the repo layout and large part of some modules are derived from [ZaneyOS](https://gitlab.com/Zaney/zaneyos).

## Features

- **Declarative Configuration:** All system and user configurations are defined declaratively using Nix.
- **Reproducible Environments:** Ensures consistent environments across different machines.
- **Modular Structure:** Configurations are broken down into reusable modules for better organization and maintainability.
- **Multi-Host Support:** Easily manage configurations for different machines (e.g., `ideapad`, `surface`).
- **Home Manager Integration:** Manages user-specific configurations (e.g., shell, applications, fonts) with Home Manager.
- **NixOS Integration:** Manages system configurations with NixOS.
- **nix-darwin Integration:** Manages macOS configurations with nix-darwin. I have not tested this but the layout works
- **Hyprland:** Configuration for the Hyprland Wayland compositor.
- **NixVim:** Integrated Neovim configuration managed by Nix.
- **Various Applications:** Configurations for `fish`, `kitty`, `tmux`, `vscodium`, `zed`, `waybar`, `rofi`, `wlogout`, and more.

## Screenshot

![Screenshot](img/empty-wallpaper.png)

## Repository Structure

- `flake.nix`: The main Nix flake definition.
- `hosts/`: Contains machine-specific NixOS configurations.
  - `ideapad/`: Configuration for my Ideapad laptop.
  - `surface/`: Configuration for my Surface device.
- `modules/`: Reusable Nix modules for both system and user configurations.
  - `core/`: Core system-wide configurations.
  - `home/`: Home Manager modules for user-specific settings.
  - `nixos/`: NixOS-specific modules.
  - `darwin/`: macOS-specific configurations (if applicable).
- `profiles/`: Defines different user profiles (e.g., `laptop`, `wsl`).
- `scripts/`: Utility scripts.
- `wallpapers/`: Directory for wallpapers.

## Installation & Usage

To use these dotfiles, you will need Nix installed. 
You can use this flake as NixOS, nix-darwin or home-manager standalone.
Make sure you enable flake support.
The general process involves cloning this repository and then using `sudo nixos-rebuild`, `sudo darwin-rebuild switch` or `home-manager switch` with the flake.

**Warning:** These are my personal dotfiles and are highly customized. Use them at your own risk and adapt them to your needs.

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/dotfiles.git ~/dotfiles # Or wherever you prefer
    cd ~/dotfiles
    ```
2.  **Change `flake-settings.nix` to match your situation**
    `user-profile`s are used to load a unique Home Manager module under `modules/home/profiles`.
    `system-profile`s are used to load a unique NixOS/nix-darwin module under `profiles/`.
    `host`s are used to load a unique NixOS/nix-darwin module under `hosts/<your-host>`.

3.  **NixOS Configuration:**
    Edit `hosts/<your-host>/` to include your auto-generated `hardware-configuration.nix`. Then, from the repository root:
    ```bash
    sudo nixos-rebuild switch --flake .
    ```
4.  **nix-darwin Configuration**
    ```bash
    sudo darwin-rebuild switch --flake .
    ```

5.  **Standalone Home Manager Configuration:**
    ```bash
    home-manager switch --flake .
    ```

## Contributing

Feel free to open issues or pull requests if you have suggestions or improvements.
