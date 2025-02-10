# Zen Browser Nix Flake

## Profile workaround

In the current state of the flake each update would create a new profile, as a workaround launch the browser after the update with `zen-browser --ProfileManager` and select the desired profile. I could fix this but this flake is just a temporary thing I'm going to maintain until the [zen browser gets added to the package repository](https://github.com/NixOS/nixpkgs/issues/327982)

## Versions

- Stable: 1.7.4b
- Experimental: 1.7.7t

## Supported Systems

- x86_64-linux
- aarch64-linux

## Installation

Add the flake output that you want to use to the appropriate package list

## Flake Outputs

- `packages.${system}.stable`: Stable release
- `packages.${system}.experimental`: Experimental release
- `packages.${system}.default`: Alias for stable release
