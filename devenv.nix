{ pkgs, ... }:

{
  packages = with pkgs; [
    git
    jq
    (python3.withPackages (pythonPackages: [ pythonPackages.pyyaml ]))
    shellcheck
    shfmt
    taplo
  ];

  scripts.check.exec = "./scripts/check.sh";

  tasks."repo:check".exec = "check";

  enterTest = ''
    check
  '';
}
