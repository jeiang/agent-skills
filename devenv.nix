{ pkgs, ... }:

{
  packages = with pkgs; [
    jq
    (python3.withPackages (pythonPackages: [ pythonPackages.pyyaml ]))
    shellcheck
    shfmt
    taplo
  ];

  tasks."repo:check".exec = "./scripts/check.sh";

  enterTest = ''
    ./scripts/check.sh
  '';
}
