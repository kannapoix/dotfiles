Install
```shell
nix run --extra-experimental-features 'nix-command flakes' github:kannapoix/dotfiles -- [HOSTNAME]
```

```shell
darwin-rebuild switch --flake .#kBook-Pro
```

```
home-manager switch --flake .#uk@kBook-Pro
```
