{lib, config, pkgs, epkgs, system, ...}: let
  cfg = config.coq;
  toE = x: if x then "t" else "nil";
in with lib; {
  options.coq = {
    package = mkOption {
      type = types.package;
      description = "Coq package that should be used";
      default = pkgs.coq;
    };

    inputs = mkOption {
      type = with types; listOf package;
      default = [];
    };

    compileBeforeRequire = {
      enable = mkOption {
        type = types.bool;
        default = true;
      };

      soundness = mkOption {
        type = types.str;
        default = "vos";
        description = "Refer to 10.4.3 of https://proofgeneral.github.io/doc/master/userman/Coq-Proof-General/";
      };
    };

    binds = {
      forward = mkOption {
        type = types.str;
        description = "Move the proof cursor forward";
        default = "C-<next>";
      };

      backward = mkOption {
        type = types.str;
        description = "Move the proof cursor backward";
        default = "C-<prior>";
      };
    };

    ui = {
      overlayArrowString = mkOption {
        type = types.str;
        description = "Character that should be overlayed on top of completed proof.";
        default = "";
        example = "_";
      };
      prettifySymbol = mkOption {
        type = types.bool;
        default = true;
      };
    };
  };

  config = {
    emacs = {
      packages = with epkgs; [
        proof-general
        company-coq
      ];
      config = ''
      (global-prettify-symbols-mode ${toE cfg.ui.prettifySymbol})
      
      (use-package proof-general
        :init
        (setq proof-splash-enable nil)
        :bind (
          ("${cfg.binds.forward}" . proof-assert-next-command-interactive)
          ("${cfg.binds.backward}" . proof-undo-last-successful-command)
        )
      )

      (use-package company-coq
        :init
        (add-hook 'coq-mode-hook #'company-coq-mode)
        :config
      )

      (setq overlay-arrow-string "${cfg.ui.overlayArrowString}")
      (setq coq-compile-before-require ${toE cfg.compileBeforeRequire.enable})
      (setq coq-compile-vos "${cfg.compileBeforeRequire.soundness}")
      '';
    };
    
    environment = {
      packages = cfg.inputs ++ [
        cfg.package
      ];
      variables.COQ_PATH = let 
        at = builtins.elemAt;
        splitted = pkgs.lib.splitString "." cfg.package.version;
        version = (at splitted 0) + "." + (at splitted 1);
      in makeSearchPath "lib/coq/${version}/user-contrib" cfg.inputs;
    };
  };
}
