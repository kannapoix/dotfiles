Install
```shell
nix --extra-experimental-features 'nix-command flakes' run github:kannapoix/dotfiles -- [HOSTNAME]
```

```shell
darwin-rebuild switch --flake .#kBook-Pro
```

```
home-manager switch --flake .#uk@kBook-Pro
```
