# nixos-configs

```sh
sudo nixos-rebuild switch
```

```sh
nix search nixpkgs sddm
```

```sh
nix-instantiate '<nixpkgs>' -A hello
nix-channel --add https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install

vim ~/.config/home-manager/home.nix

home-manager switch
```
