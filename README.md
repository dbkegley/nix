# Linux

```bash
# install nix (multi-user)
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
nix-shell -p nix-info --run "nix-info -m"
#  - system: `"x86_64-linux"`
#  - host os: `Linux 6.6.87.2-microsoft-standard-WSL2, Ubuntu, 24.04.2 LTS (Noble Numbat), nobuild`
#  - multi-user?: `yes`
#  - sandbox: `yes`
#  - version: `nix-env (Nix) 2.30.1`
#  - channels(root): `"nixpkgs"`
#  - nixpkgs: `/nix/store/kywfkiza8cbidyllz628z4ixj5c9s4f5-nixpkgs/nixpkgs`

# clone repo
nix-shell -p git --run "git clone git@github.com:dbkegley/nix.git"

# bootstrap home-manager installation
nix --extra-experimental-features "nix-command flakes" run nixpkgs#home-manager -- --extra-experimental-features "nix-command flakes" switch --flake $HOME/nix/#$USER

# set login shell for the current user.
# home-manager can update zsh configurations but cannot run privileged operations like changing a user's login shell.
echo ~/.nix-profile/bin/zsh | sudo tee -a /etc/shells
usermod -s ~/.nix-profile/bin/zsh $USER

# apply flake updates
hm-update
```


# MacOS

1. [Install nix](https://github.com/DeterminateSystems/nix-installer?tab=readme-ov-file#determinate-nix-installer)

```bash
# select no if asked about installing Determinate Nix (use vanilla)
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

2. [Install nix-darwin](https://github.com/nix-darwin/nix-darwin?tab=readme-ov-file#step-2-installing-nix-darwin)

```bash
nix run nix-darwin/nix-darwin-25.05#darwin-rebuild -- switch
```

3. Build the system

```bash
darwin-rebuild switch --flake .#david-mbp
```

### Credits

The initial version of this configuration was copied from [dc-tec](https://github.com/dc-tec/nixos-config)
