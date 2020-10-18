{ lib, pkgs, config, ... }:

with lib;
let cfg = config.iceberg.wolfram-jupyter;
in {
  options.iceberg.wolfram-jupyter = {
    enable =
      mkEnableOption "Setup Jupyter server with Wolfram Language Support.";
    mathpass = mkOption {
      type = types.str;
      example =
        "hostname	XXXX-XXXXX-XXXXX	XXXX-XXXX-XXXXXX	<mysterious string>";
      description =
        "The mathpass for Wolfram Engine. To activate, use wolframscript.";
    };
  };
  config = mkIf cfg.enable {
    # Setup MathPass
    systemd.services.jupyter.serviceConfig.ExecStartPre = let
      preStartScript = pkgs.writeShellScript "wolfram-jupyter-prestart" ''
        mkdir -p ~/.WolframEngine/Licensing/
        echo ${cfg.mathpass} > ~/.WolframEngine/Licensing/mathpass
      '';
    in preStartScript;
    services.jupyter = {
      kernels = {
        wolfram-engine = {
          argv = [
            "${pkgs.wolfram-engine}/bin/WolframKernel"
            "-script"
            "${pkgs.wolfram-jupyter-kernel}/WolframLanguageForJupyter/Resources/KernelForWolframLanguageForJupyter.wl"
            "{connection_file}"
            "ScriptInstall"
          ];
          displayName = "Wolfram Language 12.1";
          language = "Wolfram Language";
        };
      };
    };
  };
}
