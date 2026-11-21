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
      # Instruction paths for the full installations.
      harnesses = {
        claude = "CLAUDE.md";
        copilot = "instructions/agent-skills.instructions.md";
        omp = "AGENTS.md";
      };

      # instructions/<harness>-<profile>.md replaces the rendered profile
      # instructions for that harness.
      instructionsFor =
        harness: profile:
        let
          own = ./instructions + "/${harness}-${profile}.md";
        in
        if builtins.pathExists own then own else ./dist/instructions + "/${profile}.md";

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
            # A harness skill replaces a shared one of the same name; the
            # first entry of a name wins.
            [
              (./. + "/${harness}")
              ./shared
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
          mkdir -p "$out/skills"
          ${lib.optionalString (harness != "pi") ''
            instructions=$out/${harnesses.${harness}}
            mkdir -p "$out/agents" "$(dirname "$instructions")"
            {
              ${lib.optionalString (harness == "copilot") ''printf '%s\n' '---' 'applyTo: "**"' '---' ""''}
              cat ${instructionsFor harness profile}
            } >"$instructions"
          ''}
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (name: path: ''cp -r ${path} "$out/skills/${name}"'') (skillsFor harness profile)
          )}
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (name: path: ''cp ${path} "$out/agents/${name}"'') (if harness == "pi" then { } else agentsFor harness)
          )}
          ${lib.optionalString (harness == "omp") ''cp ${./instructions/omp-rules.md} "$out/RULES.md"''}
        '';
    in
    {
      # The entry names each package installs, for consumers that link one
      # entry at a time because the client owns the directory itself.
      lib = {
        inherit harnesses;
        entries = let
          full = harness: profile: {
            instructions = harnesses.${harness};
            skills = builtins.attrNames (skillsFor harness profile);
            agents = builtins.attrNames (agentsFor harness);
          } // lib.optionalAttrs (harness == "omp") { rules = "RULES.md"; };
        in {
          omp.personal = full "omp" "personal";
          omp.work = full "omp" "work";
          copilot.work = full "copilot" "work";
          claude.cloud = full "claude" "cloud";
          pi.personal.skills = builtins.attrNames (skillsFor "pi" "personal");
        };
      };

      packages = lib.genAttrs systems (
        system:
        let home = mkHome nixpkgs.legacyPackages.${system}; in {
          omp-personal = home "omp" "personal";
          omp-work = home "omp" "work";
          copilot-work = home "copilot" "work";
          claude-cloud = home "claude" "cloud";
          pi-personal = home "pi" "personal";
        }
      );
      checks = self.packages;
    };
}
