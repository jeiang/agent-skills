{ pkgs, ... }:

{
  packages = with pkgs; [
    jq
    shellcheck
    shfmt
    taplo
  ];

  languages.python = {
    enable = true;
    packages = pythonPackages: [ pythonPackages.pyyaml ];
  };

  tasks."repo:check".exec = "./scripts/check.sh";

  enterTest = ''
    ./scripts/check.sh
  '';
}
