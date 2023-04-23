{
  description = "A simple Go package";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-21.11";

  outputs = {
    self,
    nixpkgs,
  }: let
    # to work with older version of flakes
    lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

    # Generate a user-friendly version number.
    version = builtins.substring 0 8 lastModifiedDate;

    # System types to support.
    supportedSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];

    # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    # Nixpkgs instantiated for supported system types.
    nixpkgsFor = forAllSystems (system: import nixpkgs {inherit system;});
  in {
    # Provide some binary packages for selected system types.
    packages = forAllSystems (system: let
      pkgs = nixpkgsFor.${system};
    in {
      nominatim = pkgs.rPackages.buildRPackage {
        name = "nominatim";
        src = pkgs.fetchFromGitHub {
          owner = "hrbrmstr";
          repo = "nominatim";
          rev = "5c2baa9da26bc81eb769c39f6eb64fa81db01d34";
          sha256 = "mHkLo07mh1fgox7kfrUZg/IDSQQKimFmzDajyrBNmzw=";
        };
        propagatedBuildInputs = with pkgs.rPackages; [
          httr
          dplyr
          pbapply
          curl
          sp
          jsonlite
        ];
      };
    });

    # Add dependencies that are only needed for development
    devShells = forAllSystems (system: let
      pkgs = nixpkgsFor.${system};
    in {
      default = pkgs.mkShell {
        buildInputs = with pkgs; [
          R
          rPackages.httr
          rPackages.dplyr
          rPackages.pbapply
          rPackages.curl
          rPackages.sp
          rPackages.jsonlite
        ];
      };
    });

    # The default package for 'nix build'. This makes sense if the
    # flake provides only one package or there is a clear "main"
    # package.
    defaultPackage = forAllSystems (system: self.packages.${system}.nominatim);
  };
}
