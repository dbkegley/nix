

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

> nix: <https://gist.github.com/stuart-warren/66bea8c9b23fdac317598ea46b3b97d0>
> nix-darwin: <https://gist.github.com/jmatsushita/5c50ef14b4b96cb24ae5268dab613050>
> nix-darwin + nixos: <https://github.com/dustinlyons/nixos-config?tab=readme-ov-file>
> nix-darwin + nixos + wsl2: <https://github.com/dc-tec/nixos-config/tree/main?tab=readme-ov-file>


# Mac

```bash
sudo darwin-rebuild switch --flake ./nix-darwin
```
