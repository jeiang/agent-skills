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
      # Instruction file path inside each harness home, as in install.sh.
      harnesses = {
        claude = "CLAUDE.md";
        codex = "AGENTS.md";
        copilot = "instructions/agent-skills.instructions.md";
      };
      profiles = builtins.attrNames (builtins.readDir ./profiles);

      # Mirrors the layout install.sh creates under the harness home, so a
      # consumer can link $out/<entry> to ~/.<harness>/<entry>.
      mkHome =
        pkgs: harness: profile:
        pkgs.runCommand "agent-skills-${harness}-${profile}" { } ''
          src=${self}
          instructions=$out/${harnesses.${harness}}
          mkdir -p "$out/skills" "$out/agents" "$(dirname "$instructions")"
          {
            ${lib.optionalString (harness == "copilot") ''printf '%s\n' '---' 'applyTo: "**"' '---' ""''}
            cat "$src/dist/instructions/${profile}.md"
          } >"$instructions"
          for skill in "$src"/shared/* "$src"/generic/* "$src"/${harness}/*; do
            [ -f "$skill/SKILL.md" ] || continue
            name=$(basename "$skill")
            grep -Fxq "$name" "$src/profiles/${profile}/excluded-skills.txt" && continue
            cp -r "$skill" "$out/skills/$name"
          done
          for agent in "$src"/agents/${harness}/* "$src"/dist/agents/${harness}/*; do
            [ -f "$agent" ] || continue
            cp "$agent" "$out/agents/"
          done
        '';
    in
    {
      packages = lib.genAttrs systems (
        system:
        lib.listToAttrs (
          lib.mapCartesianProduct
            (
              { harness, profile }:
              lib.nameValuePair "${harness}-${profile}" (
                mkHome nixpkgs.legacyPackages.${system} harness profile
              )
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
