Install on a new machine. Pass the config name from the table below: the hostname is set by the config itself, so it is not yet known on the first run.
```shell
nix --extra-experimental-features 'nix-command flakes' run github:kannapoix/dotfiles -- <config name>
```

Apply. Each host config sets `networking.hostName`, so `darwin-rebuild` and `home-manager` pick the config for the current machine by hostname; no `#name` is needed after the first run.
```shell
sudo darwin-rebuild switch --flake ~/dotfiles
```
```shell
home-manager switch --flake ~/dotfiles
```

Hosts

| hostname / config name | nix-darwin | home-manager |
|---|---|---|
| `kBook-Pro` | hosts/mbp-2021 | home/mbp-2021 (`uk@kBook-Pro`) |
| `work-mac` | hosts/work-mac | home/work-mac (`uk@work-mac`) |
