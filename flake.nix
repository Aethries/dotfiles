{
  description = "Personal NixOS Configuration";

  nixConfig = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    noctalia.url = "github:noctalia-dev/noctalia/cachix";
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      machineConfigPath = builtins.getEnv "DOTFILES_MACHINE_CONFIG";
      machineConfig =
        if machineConfigPath != "" && builtins.pathExists machineConfigPath then
          builtins.toPath machineConfigPath
        else
          null;
      fixtureModules = [
        ./configuration.nix
        ({ lib, ... }: {
          fileSystems."/" = lib.mkDefault {
            device = "none";
            fsType = "tmpfs";
          };
          users.users.testuser = {
            isNormalUser = true;
            group = "testuser";
          };
          users.groups.testuser = { };
          dotfiles.primaryUser = "testuser";
          boot.loader.systemd-boot.enable = true;
          boot.loader.efi.canTouchEfiVariables = true;
          boot.kernelParams = [ ];
          system.stateVersion = "26.05";
        })
      ];
      checkModules = if machineConfig != null then [ machineConfig ] else fixtureModules;
    in
    {
      # Evaluation target for common modules. Real hardware stays in .machine/.
      nixosConfigurations.check = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = checkModules;
      };

      formatter.x86_64-linux = pkgs.nixfmt;
      devShells.x86_64-linux.default = pkgs.mkShellNoCC {
        packages = [
          pkgs.bashInteractive
          pkgs.jq
          pkgs.neovim
          pkgs.nixfmt
          pkgs.ripgrep
          pkgs.shellcheck
        ];
      };
    };
}
