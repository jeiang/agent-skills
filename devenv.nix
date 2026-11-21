{ pkgs, ... }:

{
  packages = with pkgs; [
    git
    jq
    (python3.withPackages (pythonPackages: [
      pythonPackages.jinja2
      pythonPackages.pyyaml
    ]))
    shellcheck
    shfmt
  ];

  scripts.check.exec = "./scripts/check.sh";

  tasks."repo:check".exec = "check";

  enterTest = ''
    check
  '';
}
