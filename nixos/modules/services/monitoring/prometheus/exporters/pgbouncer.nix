{ config, lib, pkgs, options, ... }:

let
  cfg = config.services.prometheus.exporters.pgbouncer;
  inherit (lib)
    mkOption
    mkPackageOption
    types
    optionals
    optionalString
    getExe
    getExe'
    escapeShellArg
    escapeShellArgs
    concatStringsSep
    ;
in
{
  port = 9127;
  extraOpts = {
    package = mkPackageOption pkgs "prometheus-pgbouncer-exporter" { };

    telemetryPath = mkOption {
      type = types.str;
      default = "/metrics";
      description = ''
        Path under which to expose metrics.
      '';
    };

    connectionString = mkOption {
      type = types.str;
      default = "";
      example = "postgres://admin:@localhost:6432/pgbouncer?sslmode=require";
      description = ''
        Connection string for accessing pgBouncer.

        NOTE: You MUST keep pgbouncer as database name (special internal db)!!!

        NOTE: ignore_startup_parameters MUST contain "extra_float_digits".

        NOTE: Admin user (with password or passwordless) MUST exist in the
        auth_file if auth_type other than "any" is used.

        WARNING: this secret is stored in the world-readable Nix store!
        Use {option}`connectionStringFile` instead.
      '';
    };

    connectionStringFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/run/keys/pgBouncer-connection-string";
      description = ''
        File that contains pgBouncer connection string in format:
        postgres://admin:@localhost:6432/pgbouncer?sslmode=require

        NOTE: You MUST keep pgbouncer as database name (special internal db)!!!

        NOTE: ignore_startup_parameters MUST contain "extra_float_digits".

        NOTE: Admin user (with password or passwordless) MUST exist in the
        auth_file if auth_type other than "any" is used.

        {option}`connectionStringFile` takes precedence over {option}`connectionString`
      '';
    };

    pidFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Path to PgBouncer pid file.

        If provided, the standard process metrics get exported for the PgBouncer
        process, prefixed with 'pgbouncer_process_...'. The pgbouncer_process exporter
        needs to have read access to files owned by the PgBouncer process. Depends on
        the availability of /proc.

        https://prometheus.io/docs/instrumenting/writing_clientlibs/#process-metrics.

      '';
    };

    webSystemdSocket = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Use systemd socket activation listeners instead of port listeners (Linux only).
      '';
    };

    logLevel = mkOption {
      type = types.enum [ "debug" "info" "warn" "error" ];
      default = "info";
      description = ''
        Only log messages with the given severity or above.
      '';
    };

    logFormat = mkOption {
      type = types.enum [ "logfmt" "json" ];
      default = "logfmt";
      description = ''
        Output format of log messages. One of: [logfmt, json]
      '';
    };

    webConfigFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to configuration file that can enable TLS or authentication.
      '';
    };

    extraFlags = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Extra commandline options when launching Prometheus.
      '';
    };

  };

  serviceOpts = {
    after = [ "pgbouncer.service" ];
    script = optionalString (cfg.connectionStringFile != null) ''
      connectionString=$(${escapeShellArgs [
        (getExe' pkgs.coreutils "cat") "--" cfg.connectionStringFile
      ]})
    '' + concatStringsSep " " ([
      "exec -- ${escapeShellArg (getExe cfg.package)}"
      "--web.listen-address ${cfg.listenAddress}:${toString cfg.port}"
      "--pgBouncer.connectionString ${if cfg.connectionStringFile != null
          then "\"$connectionString\""
          else "${escapeShellArg cfg.connectionString}"}"
    ] ++ optionals (cfg.telemetryPath != null) [
      "--web.telemetry-path ${escapeShellArg cfg.telemetryPath}"
    ] ++ optionals (cfg.pidFile != null) [
      "--pgBouncer.pid-file ${escapeShellArg cfg.pidFile}"
    ] ++ optionals (cfg.logLevel != null) [
      "--log.level ${escapeShellArg cfg.logLevel}"
    ] ++ optionals (cfg.logFormat != null) [
      "--log.format ${escapeShellArg cfg.logFormat}"
    ] ++ optionals (cfg.webSystemdSocket != false) [
      "--web.systemd-socket ${escapeShellArg cfg.webSystemdSocket}"
    ] ++ optionals (cfg.webConfigFile != null) [
      "--web.config.file ${escapeShellArg cfg.webConfigFile}"
    ] ++ cfg.extraFlags);

    serviceConfig.RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
  };
}
