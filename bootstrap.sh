#!/usr/bin/env bash
set -euo pipefail

pushd /home/david

cat << EOF > /etc/nix/nix.conf
build-users-group = nixbld
experimental-features = nix-command flakes
EOF

systemctl enable nix-daemon
systemctl start nix-daemon

# TODO: bootstrap ssh #

nix run nixpkgs#git clone git@github.com:dbkegley/nix.git
nix shell nixpkgs#home-manager
home-manager switch --flake ./nix/#arch

# TODO: chsh -s zsh
# add zsh to /etc/shells

popd
