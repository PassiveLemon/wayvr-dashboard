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
          version = "0-unstable-2025-1-31";

					# sourceRoot fails if we source locally
          #src = ./.;

					src = pkgs.fetchFromGitHub {
						owner = "olekolek1000";
						repo = "wayvr-dashboard";
						rev = "e68f7d022ca0b4524a9e27065404dcae4d11cf1a";
						hash = "sha256-Z8YuF9th/SaPPzo1lfw9DIdTlvrGgBapJEzmqhZ72fk=";
					};

					sourceRoot = "${src.name}/src-tauri";

					useFetchCargoVendor = true;
					cargoHash = "sha256-2Rz51zr6O8eCez1UnjkD4FYjdkhmjS/0SvfHV90og1k=";

					frontend = pkgs.buildNpmPackage {
						inherit version src;
						pname = "wayvr-dashboard-ui";

						npmDepsHash = "sha256-W2X9g0LFIgkLbZBdr4OqodeN7U/h3nVfl3mKV9dsZTg=";

						nativeBuildInputs = with pkgs; [
							autoPatchelfHook
						];

						dontAutoPatchelf = true;

						preBuild = ''
							autoPatchelf node_modules/sass-embedded-linux-x64/dart-sass/src/dart
						'';

						postBuild = ''
							cp -r dist/ $out
						'';
					};

					postPatch = ''
						substituteInPlace tauri.conf.json \
							--replace-warn '"frontendDist": "../dist"' '"frontendDist": "${frontend}"'
						substituteInPlace tauri.conf.json \
							--replace-warn '"npm run build"' '""'
					'';

          nativeBuildInputs = with pkgs; [
						pkg-config
						rustPlatform.bindgenHook
						wrapGAppsHook3
					];

					buildInputs = with pkgs; [
						alsa-lib
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

					meta.mainProgram = "wayvr_dashboard";
        };
      };
    };
  };
}
