{
  description = "WayVR Dashboard";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs = { ... } @ inputs:
  inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "x86_64-linux" ];

    perSystem = { self', system, ... }:
    let
      pkgs = import inputs.nixpkgs { inherit system; };
    in
    {
      devShells = {
        default = pkgs.mkShell {
          packages = [
            self'.packages.default.nativeBuildInputs
            self'.packages.default.buildInputs
						self'.packages.default.frontend.nativeBuildInputs
						self'.packages.default.frontend.buildInputs
          ];
        };
      };
      packages = {
        default = pkgs.rustPlatform.buildRustPackage rec {
          pname = "wayvr-dashboard";
          version = "0-unstable-2025-1-1";

          src = ./.;

					sourceRoot = "$src/src-tauri";

					useFetchCargoVendor = true;
					cargoHash = "sha256-uk9IRJDne1mgdRiEMAIwZvV9Iqwju4jGHXZyDGhYbwM=";

					frontend = pkgs.buildNpmPackage {
						inherit version src;
						pname = "wayvr-dashboard-ui";

						npmDepsHash = "sha256-yitR04QOXZWDj6t0LmsnIqlZmQKLu19mzTflfuZPH3U=";

						postBuild = ''
							cp -r dist/ $out
						'';
					};

					postPatch = ''
						cp -r $frontend ./frontend

						substituteInPlace tauri.conf.json \
							--replace-fail '"frontendDist": "../dist"' '"frontendDist": "./frontend"'
					'';

          nativeBuildInputs = with pkgs; [
						pkg-config
						rustPlatform.bindgenHook
						wrapGAppsHook3
					];

					buildInputs = with pkgs; [
						curl
						dbus
						glib
						gtk3
						librsvg
						libsoup_2_4
						openssl
						webkitgtk_4_1
						wget
					];

					doCheck = false;
        };
      };
    };
  };
}
