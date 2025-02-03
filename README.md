# Zen Browser Nix Flake

## Versions

- Stable: 1.7.4b
- Experimental: 1.7.4t

## Supported Systems

- x86_64-linux
- aarch64-linux

## Installation

Add the flake output that you want to use to the appropriate package list

## Flake Outputs

- `packages.${system}.stable`: Stable release
- `packages.${system}.experimental`: Experimental release
- `packages.${system}.default`: Alias for stable release
