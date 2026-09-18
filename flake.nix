{
  description = "Agent skills, subagents, and instructions as immutable per-harness trees";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      # Instruction file path inside each harness home, as in install.sh. The
      # omp home is ~/.omp/agent rather than ~/.omp.
      harnesses = {
        claude = "CLAUDE.md";
        codex = "AGENTS.md";
        copilot = "instructions/agent-skills.instructions.md";
        omp = "AGENTS.md";
      };
      profiles = builtins.attrNames (builtins.readDir ./profiles);

      entriesOf =
        type: dir:
        lib.optionals (builtins.pathExists dir) (
          builtins.attrNames (lib.filterAttrs (_: t: t == type) (builtins.readDir dir))
        );

      # The skill and agent roots install.sh reads, with the profile's
      # exclusions applied. Names are the entry names under the harness home.
      skillsFor =
        harness: profile:
        let
          excluded = lib.splitString "\n" (
            builtins.readFile (./profiles + "/${profile}/excluded-skills.txt")
          );
          keep = root: name: builtins.pathExists "${root}/${name}/SKILL.md" && !(lib.elem name excluded);
        in
        lib.listToAttrs (
          lib.concatMap
            (
              root:
              map (name: lib.nameValuePair name "${root}/${name}") (
                lib.filter (keep root) (entriesOf "directory" root)
              )
            )
            [
              ./shared
              ./generic
              (./. + "/${harness}")
            ]
        );

      agentsFor =
        harness:
        lib.listToAttrs (
          lib.concatMap
            (root: map (name: lib.nameValuePair name "${root}/${name}") (entriesOf "regular" root))
            [
              # dist/ is rendered output and wins over a same-named source agent.
              (./dist/agents + "/${harness}")
              (./agents + "/${harness}")
            ]
        );

      # Mirrors the layout install.sh creates under the harness home, so a
      # consumer can link $out/<entry> to ~/.<harness>/<entry>.
      mkHome =
        pkgs: harness: profile:
        pkgs.runCommand "agent-skills-${harness}-${profile}" { } ''
          instructions=$out/${harnesses.${harness}}
          mkdir -p "$out/skills" "$out/agents" "$(dirname "$instructions")"
          {
            ${lib.optionalString (harness == "copilot") ''printf '%s\n' '---' 'applyTo: "**"' '---' ""''}
            cat ${./dist/instructions}/${profile}.md
          } >"$instructions"
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (name: path: ''cp -r ${path} "$out/skills/${name}"'') (skillsFor harness profile)
          )}
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (name: path: ''cp ${path} "$out/agents/${name}"'') (agentsFor harness)
          )}
        '';
    in
    {
      # The entry names each package installs, for consumers that link one
      # entry at a time because the client owns the directory itself.
      lib = {
        inherit harnesses;
        entries = lib.mapAttrs (
          harness: instructions:
          lib.genAttrs profiles (profile: {
            inherit instructions;
            skills = builtins.attrNames (skillsFor harness profile);
            agents = builtins.attrNames (agentsFor harness);
          })
        ) harnesses;
      };

      packages = lib.genAttrs systems (
        system:
        lib.listToAttrs (
          lib.mapCartesianProduct
            (
              { harness, profile }:
              lib.nameValuePair "${harness}-${profile}" (mkHome nixpkgs.legacyPackages.${system} harness profile)
            )
            {
              harness = builtins.attrNames harnesses;
              profile = profiles;
            }
        )
      );
      checks = self.packages;
    };
}
