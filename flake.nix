{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { utils, nixpkgs, ... }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      rec {
        packages.default = packages.container;

        packages.webserver = pkgs.stdenv.mkDerivation {
          name = "webserver";
          src = ./.;
          buildInputs = [
              pkgs.cacert
              pkgs.python3
          ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          installPhase = ''
            mkdir -p $out/bin $out/www
            cp ./index.html $out/www/

            # Create a simple HTTP server script
            cat > $out/bin/serve <<EOF
            #!/bin/bash
            cd $out/www
            exec ${pkgs.python3}/bin/python3 -m http.server 3000
            EOF

            chmod +x $out/bin/serve
          '';
        };

        packages.container = pkgs.dockerTools.buildLayeredImage {
          name = "openfrontpro";
          contents = [
            packages.webserver
            pkgs.python3
            pkgs.bash
            pkgs.coreutils
          ];

          config = {
            ExposedPorts = { "3000/tcp" = { }; };
            EntryPoint = [ "${packages.webserver}/bin/serve" ];
            Env = [
            ];
          };
        };
      }
    );
}

