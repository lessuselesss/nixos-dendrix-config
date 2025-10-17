# 04.03 JDD Index
# Maintains an index of all JDD modules for conflict detection and documentation
{ inputs, ... }:

{
  flake.nixosModules."04.03-jdd-index" = { config, lib, pkgs, ... }:
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

        def extract_module_attribute_name(file_path: Path) -> str | None:
            """Extract the flake.nixosModules attribute name from a .nix file"""
            try:
                content = file_path.read_text()
                # Match: flake.nixosModules.NAME or flake.nixosModules."NAME"
                pattern = r'flake\.nixosModules\.(?:"([^"]+)"|([a-zA-Z0-9._-]+))'
                match = re.search(pattern, content)
                if match:
                    return match.group(1) or match.group(2)
                return None
            except Exception as e:
                print(f"Warning: Could not read {file_path}: {e}", file=sys.stderr)
                return None

        def validate_attribute_name(filename: str, attribute_name: str | None, parsed: dict) -> dict:
            """Validate that attribute name matches expected pattern from filename

            Johnny Decimal Structure:
            - Filename: A0-A9_area__AC-category__AC.ID--aspect-name.nix
            - Attribute: "AC.ID-aspect-name"

            Where:
            - A0-A9: Area range (e.g., 10-19)
            - AC: Category number (must fall within Area range)
            - ID: Two-digit identifier
            - AC.ID: Johnny Decimal index
            """
            validation = {
                "has_attribute": attribute_name is not None,
                "attribute_name": attribute_name,
                "expected_attribute": None,
                "matches_pattern": False,
                "errors": [],
            }

            if not attribute_name:
                validation["errors"].append("No flake.nixosModules attribute found in file")
                return validation

            # Extract Johnny Decimal components from filename
            category = parsed["subcategory_number"]  # AC (e.g., 12)
            item_id = int(f"{parsed['version_major']}{parsed['version_minor']:02d}")  # Reconstruct full ID

            # Actually, the filename structure is: AC-category__AC.ID--aspect-name
            # Where AC is subcategory_number and ID is constructed from version_major.version_minor
            ac = parsed["subcategory_number"]  # Category number (e.g., 12)
            jdd_id = f"{parsed['version_major']:02d}.{parsed['version_minor']:02d}"  # JDD Index (e.g., 12.02)
            aspect_name = parsed["description"]  # aspect-name from filename

            # Expected attribute: "AC.ID-aspect-name"
            expected = f"{jdd_id}-{aspect_name}"
            validation["expected_attribute"] = expected

            # Parse the actual attribute name
            # Pattern: AC.ID-aspect-name (e.g., "12.02-btrfs-validation")
            attr_pattern = r'^(\d{2})\.(\d{2})-([a-z0-9-]+)$'
            attr_match = re.match(attr_pattern, attribute_name)

            if not attr_match:
                validation["errors"].append(
                    f"Attribute name '{attribute_name}' doesn't match AC.ID-aspect-name pattern"
                )
                return validation

            attr_ac, attr_id, attr_aspect = attr_match.groups()
            attr_jdd = f"{attr_ac}.{attr_id}"

            # Validate Category (AC) matches
            if int(attr_ac) != ac:
                validation["errors"].append(
                    f"Category (AC) mismatch: attribute has {attr_ac}, filename has {ac:02d}"
                )

            # Validate ID matches
            if attr_id != f"{parsed['version_minor']:02d}":
                validation["errors"].append(
                    f"ID mismatch: attribute has {attr_id}, filename has {parsed['version_minor']:02d}"
                )

            # Validate JDD index matches
            if attr_jdd != jdd_id:
                validation["errors"].append(
                    f"Johnny Decimal index mismatch: attribute has {attr_jdd}, filename has {jdd_id}"
                )

            # Validate aspect name matches
            if attr_aspect != aspect_name:
                validation["errors"].append(
                    f"Aspect name mismatch: attribute has '{attr_aspect}', filename has '{aspect_name}'"
                )

            # Check if everything matches
            if attribute_name == expected:
                validation["matches_pattern"] = True

            return validation

        def parse_jdd_filename(filename: str, file_path: Path = None) -> dict:
            """Parse a JDD filename into components and validate attribute name

            Filename pattern: A0-A9_area-name__AC-category-name__AC.ID--aspect-name.nix
            Example: 10-19_system__12-disk__12.02--btrfs-validation.nix
            """
            match = re.match(JDD_PATTERN, filename)
            if not match:
                return None

            # Parse filename components
            # Pattern groups: (A0)-(A9)_(area)__(AC)-(category)__(AC).(ID)--(aspect).nix
            range_start, range_end, area_name, category_ac, category_name, jdd_ac, jdd_id, aspect_name = match.groups()

            parsed = {
                "filename": filename,
                # Area information
                "area_range": f"{range_start}-{range_end}",  # A0-A9 (e.g., "10-19")
                "range_start": int(range_start),
                "range_end": int(range_end),
                "area_name": area_name,  # e.g., "system"
                # Category information
                "category": int(category_ac),  # AC (e.g., 12)
                "category_name": category_name,  # e.g., "disk"
                # Legacy names for compatibility
                "subcategory_number": int(category_ac),
                "subcategory": category_name,
                # Johnny Decimal index (AC.ID)
                "jdd_index": f"{jdd_ac}.{jdd_id}",  # e.g., "12.02"
                "version_major": int(jdd_ac),  # AC part
                "version_minor": int(jdd_id),  # ID part
                # Aspect/description
                "aspect_name": aspect_name,  # e.g., "btrfs-validation"
                "description": aspect_name,  # Legacy name
            }

            # Extract and validate attribute name if file path provided
            if file_path:
                attribute_name = extract_module_attribute_name(file_path)
                validation = validate_attribute_name(filename, attribute_name, parsed)
                parsed["attribute"] = validation

            return parsed

        def build_index(modules_dir: Path) -> dict:
            """Build comprehensive index of all JDD modules"""
            index = {
                "modules": [],
                "by_range": defaultdict(list),
                "by_category": defaultdict(list),
                "by_subcategory": defaultdict(list),
                "used_numbers": defaultdict(set),
                "validation_errors": [],
                "statistics": {},
            }

            # Scan all .nix files in modules directory
            for nix_file in sorted(modules_dir.glob("*.nix")):
                parsed = parse_jdd_filename(nix_file.name, nix_file)
                if parsed:
                    index["modules"].append(parsed)

                    # Group by Area range (A0-A9)
                    area_range = parsed["area_range"]  # e.g., "10-19"
                    index["by_range"][area_range].append(parsed)

                    # Group by Category (AC)
                    category_name = parsed["category_name"]  # e.g., "disk"
                    index["by_category"][category_name].append(parsed)

                    # Group by Category+Name (e.g., "12-disk")
                    cat_key = f"{parsed['category']}-{parsed['category_name']}"
                    index["by_subcategory"][cat_key].append(parsed)

                    # Track used Category numbers within each Area
                    index["used_numbers"][area_range].add(parsed["category"])

                    # Track used JDD indices (AC.ID) per category
                    jdd_key = f"{area_range}_{cat_key}"
                    if jdd_key not in index["used_numbers"]:
                        index["used_numbers"][jdd_key] = set()
                    # Store JDD index as tuple (AC, ID)
                    index["used_numbers"][jdd_key].add(
                        (parsed["version_major"], parsed["version_minor"])
                    )

                    # Collect validation errors
                    if "attribute" in parsed:
                        attr_validation = parsed["attribute"]
                        if attr_validation["errors"]:
                            for error in attr_validation["errors"]:
                                index["validation_errors"].append({
                                    "filename": parsed["filename"],
                                    "attribute": attr_validation["attribute_name"],
                                    "expected": attr_validation["expected_attribute"],
                                    "error": error,
                                })

            # Convert sets to lists for JSON serialization
            index["used_numbers"] = {
                k: list(v) if isinstance(v, set) else v
                for k, v in index["used_numbers"].items()
            }

            # Calculate statistics
            modules_with_attributes = sum(
                1 for m in index["modules"]
                if "attribute" in m and m["attribute"]["has_attribute"]
            )
            modules_with_valid_attributes = sum(
                1 for m in index["modules"]
                if "attribute" in m and m["attribute"]["matches_pattern"]
            )

            index["statistics"] = {
                "total_modules": len(index["modules"]),
                "ranges": len(index["by_range"]),
                "categories": len(index["by_category"]),
                "subcategories": len(index["by_subcategory"]),
                "modules_with_attributes": modules_with_attributes,
                "modules_with_valid_attributes": modules_with_valid_attributes,
                "validation_errors": len(index["validation_errors"]),
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

            stats = index['statistics']
            print(f"✅ Built JDD index: {stats['total_modules']} modules")
            print(f"   - Modules with attributes: {stats['modules_with_attributes']}/{stats['total_modules']}")
            print(f"   - Valid attribute names: {stats['modules_with_valid_attributes']}/{stats['modules_with_attributes']}")

            if index['validation_errors']:
                print(f"\n⚠️  {len(index['validation_errors'])} validation error(s) found:")
                for error in index['validation_errors']:
                    print(f"   {error['filename']}:")
                    print(f"     - {error['error']}")
                    if error['expected']:
                        print(f"     - Expected: {error['expected']}")

            print(f"\n   Output: {output_file}")
      '';

      # Generate the index at build time
      jddIndexFile = pkgs.runCommand "jdd-index.json" {
        buildInputs = [ jddIndexBuilder pkgs.python3 ];
        # Copy the modules directory into the build
        modulesDir = lib.fileset.toSource {
          root = ./..;
          fileset = lib.fileset.fileFilter (file: file.hasExt "nix") ./..;
        };
      } ''
        # Build index from modules subdirectory
        ${jddIndexBuilder}/bin/jdd-build-index "$modulesDir/modules" "$out"
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
