# 04.03 JDD Index
# Maintains an index of all JDD modules for conflict detection and documentation
{ inputs, ... }:

{
  flake.nixosModules.jdd-index = { config, lib, pkgs, ... }:
    let
      # Scan modules directory and build index
      jddIndexBuilder = pkgs.writeScriptBin "jdd-build-index" ''
        #!${pkgs.python3}/bin/python3
        """
        JDD Index Builder

        Scans modules/ directory and builds a comprehensive index of:
        - All module filenames
        - Category/subcategory/version numbers in use
        - Module descriptions
        - Conflict detection data
        """
        import json
        import re
        from pathlib import Path
        from collections import defaultdict

        # Pattern for JDD filenames
        JDD_PATTERN = r'^(\d{2})-(\d{2})_([a-z][a-z-]*)__(\d{2})-([a-z][a-z-]*)__(\d{2})\.(\d{2})--([a-z0-9][a-z0-9-]*)\.nix$'

        def parse_jdd_filename(filename: str) -> dict:
            """Parse a JDD filename into components"""
            match = re.match(JDD_PATTERN, filename)
            if not match:
                return None

            range_start, range_end, category, sub_num, subcategory, major, minor, desc = match.groups()

            return {
                "filename": filename,
                "range": f"{range_start}-{range_end}",
                "range_start": int(range_start),
                "range_end": int(range_end),
                "category": category,
                "subcategory_number": int(sub_num),
                "subcategory": subcategory,
                "version_major": int(major),
                "version_minor": int(minor),
                "description": desc,
            }

        def build_index(modules_dir: Path) -> dict:
            """Build comprehensive index of all JDD modules"""
            index = {
                "modules": [],
                "by_range": defaultdict(list),
                "by_category": defaultdict(list),
                "by_subcategory": defaultdict(list),
                "used_numbers": defaultdict(set),
                "statistics": {},
            }

            # Scan all .nix files in modules directory
            for nix_file in sorted(modules_dir.glob("*.nix")):
                parsed = parse_jdd_filename(nix_file.name)
                if parsed:
                    index["modules"].append(parsed)

                    # Group by range
                    range_key = parsed["range"]
                    index["by_range"][range_key].append(parsed)

                    # Group by category
                    index["by_category"][parsed["category"]].append(parsed)

                    # Group by subcategory
                    subcat_key = f"{parsed['subcategory_number']}-{parsed['subcategory']}"
                    index["by_subcategory"][subcat_key].append(parsed)

                    # Track used numbers
                    index["used_numbers"][range_key].add(parsed["subcategory_number"])

                    # Track version numbers per subcategory
                    version_key = f"{range_key}_{subcat_key}"
                    if version_key not in index["used_numbers"]:
                        index["used_numbers"][version_key] = set()
                    index["used_numbers"][version_key].add(
                        (parsed["version_major"], parsed["version_minor"])
                    )

            # Convert sets to lists for JSON serialization
            index["used_numbers"] = {
                k: list(v) if isinstance(v, set) else v
                for k, v in index["used_numbers"].items()
            }

            # Calculate statistics
            index["statistics"] = {
                "total_modules": len(index["modules"]),
                "ranges": len(index["by_range"]),
                "categories": len(index["by_category"]),
                "subcategories": len(index["by_subcategory"]),
            }

            return index

        def suggest_next_available(index: dict, range_key: str, subcategory: str) -> tuple:
            """Suggest next available version number for a subcategory"""
            subcat_search = f"{range_key}_{subcategory}"
            used_versions = []

            for key, versions in index["used_numbers"].items():
                if key.startswith(subcat_search):
                    used_versions.extend(versions)

            # Find next available major.minor
            if not used_versions:
                return (1, 1)  # Start with 01.01

            # Sort and find gaps
            used_versions.sort()
            last_major, last_minor = used_versions[-1]

            # Suggest incrementing minor version
            return (last_major, last_minor + 1)

        if __name__ == "__main__":
            import sys

            if len(sys.argv) < 2:
                print("Usage: jdd-build-index <modules_directory> [output_file]")
                sys.exit(1)

            modules_dir = Path(sys.argv[1])
            output_file = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("/tmp/jdd-index.json")

            if not modules_dir.exists():
                print(f"Error: Directory {modules_dir} does not exist")
                sys.exit(1)

            # Build index
            index = build_index(modules_dir)

            # Write to file
            with open(output_file, 'w') as f:
                json.dump(index, f, indent=2, default=str)

            print(f"✅ Built JDD index: {index['statistics']['total_modules']} modules")
            print(f"   Output: {output_file}")
      '';

      # Generate the index at build time
      jddIndexFile = pkgs.runCommand "jdd-index.json" {
        buildInputs = [ jddIndexBuilder ];
      } ''
        # Get the source directory
        SRC_DIR="${./../../modules}"

        # Build index
        ${jddIndexBuilder}/bin/jdd-build-index "$SRC_DIR" "$out"
      '';

      # Generate human-readable documentation
      jddDocGenerator = pkgs.writeScriptBin "jdd-generate-docs" ''
        #!${pkgs.python3}/bin/python3
        """
        Generate markdown documentation from JDD index
        """
        import json
        import sys
        from pathlib import Path

        def generate_markdown(index: dict) -> str:
            """Generate markdown documentation from index"""
            md = ["# JDD Module Index", ""]
            md.append(f"**Total Modules**: {index['statistics']['total_modules']}")
            md.append(f"**Categories**: {index['statistics']['categories']}")
            md.append(f"**Subcategories**: {index['statistics']['subcategories']}")
            md.append("")

            # Group by range
            for range_key in sorted(index['by_range'].keys()):
                modules = index['by_range'][range_key]
                md.append(f"## Range {range_key}")
                md.append("")

                # Group by subcategory within range
                subcats = {}
                for mod in modules:
                    subcat = f"{mod['subcategory_number']}-{mod['subcategory']}"
                    if subcat not in subcats:
                        subcats[subcat] = []
                    subcats[subcat].append(mod)

                for subcat in sorted(subcats.keys()):
                    subcat_mods = subcats[subcat]
                    md.append(f"### {subcat}")
                    md.append("")

                    for mod in sorted(subcat_mods, key=lambda m: (m['version_major'], m['version_minor'])):
                        version = f"{mod['version_major']:02d}.{mod['version_minor']:02d}"
                        md.append(f"- **{version}**: `{mod['filename']}`")

                    md.append("")

            return "\n".join(md)

        if __name__ == "__main__":
            if len(sys.argv) < 2:
                print("Usage: jdd-generate-docs <index.json> [output.md]")
                sys.exit(1)

            index_file = Path(sys.argv[1])
            output_file = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("/tmp/jdd-modules.md")

            with open(index_file) as f:
                index = json.load(f)

            markdown = generate_markdown(index)

            with open(output_file, 'w') as f:
                f.write(markdown)

            print(f"✅ Generated documentation: {output_file}")
      '';
    in
    {
      # Install index tools
      environment.systemPackages = [
        jddIndexBuilder
        jddDocGenerator
      ];

      # Make index available system-wide
      environment.etc."jdd/index.json".source = jddIndexFile;

      # Generate docs on activation
      system.activationScripts.jdd-update-docs = lib.stringAfter [ "etc" ] ''
        # Generate up-to-date documentation
        ${jddDocGenerator}/bin/jdd-generate-docs /etc/jdd/index.json /etc/jdd/modules.md || true
      '';
    };
}
