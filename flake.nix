{
  description = "Bichon - A lightweight, high-performance Rust email archiver with WebUI";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      packageName = "bichon";
      repositoryRev = "0.3.0";
      repositoryRevHash = "sha256-AY5VVQEYcuvMZ0tskiOwPEIBHa1MgOKQ+QVI5Hz9pk4=";
      nodeModulesHash = "sha256-66fcn9dSozgcVl9pAOwmz1nqfsQgzcb4N+oJWEPe7gE=";
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      nixosModules = {
        bichon =
          {
            config,
            lib,
            pkgs,
            ...
          }:
          let
            cfg = config.services.bichon;
            boolToString = b: if (builtins.isBool b) && b then "true" else "false";
            env = {
              BICHON_LOG_LEVEL = cfg.log.level;
              BICHON_ANSI_LOGS = boolToString cfg.log.ansi;
              BICHON_LOG_TO_FILE = boolToString cfg.log.toFile;
              BICHON_JSON_LOGS = boolToString cfg.log.json;
              BICHON_MAX_SERVER_LOG_FILES = toString cfg.log.maxFiles;
              BICHON_HTTP_PORT = toString cfg.port;
              BICHON_BIND_IP = cfg.listenIp;
              BICHON_PUBLIC_URL = cfg.publicUrl;
              BICHON_CORS_MAX_AGE = toString cfg.cors.maxAge;
              BICHON_ENCRYPT_PASSWORD = cfg.encryptPassword;
              BICHON_ENCRYPT_PASSWORD_FILE = cfg.encryptPasswordFile;
              BICHON_ROOT_DIR = cfg.db.rootDir;
              BICHON_METADATA_CACHE_SIZE = toString cfg.db.metadataCacheSize;
              BICHON_ENVELOPE_CACHE_SIZE = toString cfg.db.envelopeCacheSize;
              BICHON_ENABLE_ACCESS_TOKEN = boolToString cfg.enableAccessToken;
              BICHON_ENABLE_REST_HTTPS = boolToString cfg.enableRestHttps;
              BICHON_HTTP_COMPRESSION_ENABLED = boolToString cfg.enableHttpCompression;
            }
            # the following can be null and bichon doesn't like empty-valued non-string env vars
            // (
              if cfg.syncConcurrency != null then
                {
                  BICHON_SYNC_CONCURRENCY = toString cfg.syncConcurrency;
                }
              else
                { }
            );
          in
          {
            options.services.bichon = {
              enable = lib.mkEnableOption ''
                Enable the bichon service.
              '';

              user = lib.mkOption {
                type = lib.types.str;
                default = "bichon";
                description = ''
                  The user to run the service as.
                '';
              };

              group = lib.mkOption {
                type = lib.types.str;
                default = "bichon";
                description = ''
                  The user group to run the service as.
                '';
              };

              log = lib.mkOption {
                type = lib.types.submodule {
                  options = {
                    level = lib.mkOption {
                      type = lib.types.str;
                      default = "info";
                      description = ''
                        The log level for bichon.
                      '';
                    };
                    ansi = lib.mkOption {
                      type = lib.types.bool;
                      default = false;
                      description = "ANSI-formatted logs";
                    };
                    toFile = lib.mkOption {
                      type = lib.types.bool;
                      default = false;
                      description = "If true, log to file, otherwise log to stdout (the default).";
                    };
                    json = lib.mkOption {
                      type = lib.types.bool;
                      default = false;
                      description = "JSON-formatted logs (disabled by default)";
                    };
                    maxFiles = lib.mkOption {
                      type = lib.types.int;
                      default = 5;
                      description = "Max number of server log files to keep";
                    };
                  };
                };
                default = { };
                description = "Logging settings";
              };

              port = lib.mkOption {
                type = lib.types.port;
                default = 15360;
                description = ''
                  The port on which the bichon server will listen.
                '';
              };

              listenIp = lib.mkOption {
                type = lib.types.str;
                default = "0.0.0.0";
                description = ''
                  The IPv4 address to server should listen on.
                '';
              };

              publicUrl = lib.mkOption {
                type = lib.types.str;
                default = "http://localhost:15360";
                description = ''
                  The public URL on which the server will be reachable.
                '';
              };

              cors = lib.mkOption {
                type = lib.types.submodule {
                  options = {
                    origins = lib.mkOption {
                      type = lib.types.nullOr (lib.types.separatedString ",");
                      default = null;
                      description = ''
                        Set of the allowed CORS origins (comma-separated list)
                      '';
                    };
                    maxAge = lib.mkOption {
                      type = lib.types.int;
                      default = 86400;
                      description = "CORS max age in seconds";
                    };
                  };
                };
                default = { };
                description = "CORS settings";
              };

              encryptPassword = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "The encryption password for the sensitive data";
              };

              encryptPasswordFile = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "The path to the file with the encryption password for the sensitive data";
              };

              db = lib.mkOption {
                type = lib.types.submodule {
                  options = {
                    rootDir = lib.mkOption {
                      type = lib.types.str;
                      default = "/var/lib/bichon";
                      description = "Absolute path to the bichon database root directory.";
                    };
                    metadataCacheSize = lib.mkOption {
                      type = lib.types.int;
                      default = 134217728;
                      description = "The size of the metadata cache in bytes.";
                    };
                    envelopeCacheSize = lib.mkOption {
                      type = lib.types.int;
                      default = 1073741824;
                      description = "The size of the envelope cache in bytes.";
                    };
                  };
                };
                default = { };
                description = "The configuration of the bichon database";
              };

              enableAccessToken = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Enable/disable authentication through an access token for the HTTP endpoints.";
              };

              enableRestHttps = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Enable/disable HTTPS for the REST endpoints.";
              };

              enableHttpCompression = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Enable/disable HTTP compression for the OpenAPI server.";
              };

              syncConcurrency = lib.mkOption {
                type = lib.types.nullOr lib.types.ints.positive;
                default = null;
                description = "Maximum number of concurrent email sync tasks (default: number of CPUs * 2)";
              };
            };

            config = lib.mkIf cfg.enable {
              users = {
                users."${cfg.user}" = {
                  isSystemUser = true;
                  group = cfg.group;
                  linger = true;
                };
                groups."${cfg.group}" = { };
              };
              systemd.services.bichon = {
                description = "Bichon - A lightweight, high-performance Rust email archiver with WebUI";

                after = [ "network-online.target" ];
                wants = [ "network-online.target" ];
                wantedBy = [ "multi-user.target" ];

                environment = env;

                serviceConfig = {
                  User = cfg.user;
                  Group = cfg.group;
                  Restart = "always";
                  ExecStart = "${lib.getBin self.packages."${pkgs.stdenv.hostPlatform.system}"."${packageName}"}/bin/bichon";
                  StateDirectory = lib.mkIf (cfg.db.rootDir == "/var/lib/bichon") "bichon";
                };
              };
              systemd.tmpfiles.settings = lib.mkIf (cfg.db.rootDir != "/var/lib/bichon") {
                bichon."${cfg.db.rootDir}".e = {
                  user = cfg.user;
                  group = cfg.group;
                  mask = 0700;
                };
              };
            };
          };
      };

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          lib = pkgs.lib;
          source = pkgs.fetchFromGitHub {
            owner = "rustmailer";
            repo = "bichon";
            rev = repositoryRev;
            hash = repositoryRevHash;
          };
        in
        {
          "${packageName}" = pkgs.rustPlatform.buildRustPackage (
            finalAttrs:
            let
              manifest = (lib.importTOML "${finalAttrs.src}/Cargo.toml").package;
              frontend = pkgs.stdenv.mkDerivation (finalAttrs: {
                pname = "${packageName}-frontend";
                version = manifest.version;

                src = source;

                sourceRoot = "${finalAttrs.src.name}/web";

                nativeBuildInputs = [
                  pkgs.nodejs_22
                  pkgs.pnpm_10
                  pkgs.pnpmConfigHook
                  pkgs.typescript
                ];

                pnpmDeps = pkgs.fetchPnpmDeps {
                  inherit (finalAttrs) pname version src;
                  fetcherVersion = 2;
                  hash = nodeModulesHash;
                  sourceRoot = "${finalAttrs.src.name}/web";
                };

                patchPhase = ''
                  export CI=true
                '';

                buildPhase = ''
                  runHook preBuild

                  pnpm build

                  runHook postBuild
                '';

                installPhase = ''
                  runHook preInstall

                  mkdir -p $out;
                  cp -r dist $out/;

                  runHook postInstall
                '';
              });
            in
            {
              pname = "${packageName}";
              version = manifest.version;
              src = source;

              cargoLock = {
                lockFile = "${finalAttrs.src}/Cargo.lock";
              };
              nativeBuildInputs = [
                pkgs.pkg-config
                pkgs.git
              ];
              buildInputs = [
                pkgs.openssl
              ];
              preBuild = ''
                echo "moving the frontend code to the expected location"
                mkdir -p "web/dist"
                cp -r "${frontend}" web/dist
              '';

              # bichon doesn't have many tests yet and they're failing, too :)
              doCheck = false;
            }
          );
          default = self.packages.${system}.${packageName};
        }
      );
    };
}
